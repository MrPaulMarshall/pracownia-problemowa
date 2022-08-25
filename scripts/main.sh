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
for N in C_NODES_LIST
do
    ## prepare subdirectory
    RUN_DIR=${BASE_DIR}/workspace/n_${N}
    mkdir -p ${RUN_DIR}

    ## start measuring time
    T_START=$(timestamp)

    ## generate jobs -- TODO: customize names of the directory to avoid conflict if 2 tasks are started in 1 second
    generatemc -p ${C_PRIMARIES} -j ${N} ${BASE_DIR}/input/data/ --workspace ${RUN_DIR} --scheduler_options "[--time=0:15:00 -A plgccbmc11-cpu]"

    ## run simulation

    ## collect results

    ## end measuring time
    T_END=$(timestamp)

    ## save the final measure -- TODO: do some actual saving
    T_EXEC_SECS=$(( (T_END - T_START) / 1000000000 ))
    T_EXEC_NANS=$(( (T_END - T_START) % 1000000000 ))

    echo "Executions for ${N} nodes took: ${T_EXEC_SECS} seconds, ${T_EXEC_NANS} nanoseconds"
done

## generate plots


## clean-up
