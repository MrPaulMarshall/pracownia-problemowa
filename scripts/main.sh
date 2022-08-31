#!/bin/bash

## define utilities
now() { # get the current date-time in YYYYMMDD-HHMMSS format
    date +"%Y%m%d-%H%M%S"
}

timestamp() { # get nanoseconds from the Epoch
    date +"%s%N"
}

## parse config
source $PWD/input/config.txt

## download binaries
if [[ -f $PWD/bin/generatemc && -f $PWD/bin/convertmc ]]; then
    echo "Binaries already present (generatemc: v$($PWD/bin/generatemc --version), convertmc: v$($PWD/bin/convertmc --version))"
else
    $PWD/scripts/download_binaries.sh
fi

## activate env
source $PWD/scripts/activate_env.sh

## create directories -- TODO: maybe structure needs changes
BASE_DIR=$PWD/results/run_$(now)
mkdir -p ${BASE_DIR}/input/data
mkdir -p ${BASE_DIR}/log
mkdir -p ${BASE_DIR}/output/raw ${BASE_DIR}/output/aggregates
mkdir -p ${BASE_DIR}/workspace

## copy input data, if missing resort to defaults
cp $PWD/input/config.txt ${BASE_DIR}/input/

for NAME in beam detect geo mat
do
    if [ -f $PWD/input/data/$NAME.dat ]; then
        cp $PWD/input/data/$NAME.dat ${BASE_DIR}/input/data/
    else
        cp $PWD/input/default/$NAME.dat ${BASE_DIR}/input/data/
    fi
done

## prepare and run simulation for each number of nodes
for N in "${C_NODES_LIST[@]}"
do
    ## prepare subdirectory
    RUN_DIR=${BASE_DIR}/workspace/n_${N}
    mkdir -p ${RUN_DIR}

    ## start measuring time
    T_START=$(timestamp)

    ## generate jobs -- TODO: customize names of the directory to avoid conflict if 2 tasks are started in 1 second
    echo "Generating run: (P=${C_PRIMARIES}, N=${N}, DIR=${RUN_DIR})"
    generatemc -p ${C_PRIMARIES} -j ${N} ${BASE_DIR}/input/data/ --workspace ${RUN_DIR} --scheduler_options "[--time=0:15:00 -A plgccbmc11-cpu]"

    ## run simulation
    for run_path in ${RUN_DIR}/run_*
    do
        sh $run_path/submit.sh
        SED=$(sed -n 9p $run_path/submit.log)
        arrIN=(${SED//;/ })
        COLLECT_ID=$(echo ${arrIN[2]})
        echo $COLLECT_ID
    done
    # sacct -j 533631 --json >> xd.json
    ## end measuring time
    T_END=$(timestamp)

    ## save the final measure -- TODO: do some actual saving
    T_EXEC_SECS=$(( (T_END - T_START) / 1000000000 ))
    T_EXEC_NANS=$(( (T_END - T_START) % 1000000000 ))

    echo "Run with ${N} nodes took: ${T_EXEC_SECS}s ${T_EXEC_NANS}ns"
    printf "%d.%09d" ${T_EXEC_SECS} ${T_EXEC_NANS} > ${RUN_DIR}/time.txt
done

## collect data
echo "nodes,exec_time" > ${BASE_DIR}/output/raw/times.csv

for N in "${C_NODES_LIST[@]}"
do
    RUN_DIR=${BASE_DIR}/workspace/n_${N}
    echo "${N},$(cat ${RUN_DIR}/time.txt)" >> ${BASE_DIR}/output/raw/times.csv
done

## generate plots
echo "Not implemented yet :)" > ${BASE_DIR}/output/aggregates/image.txt

## clean-up

