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
echo ""

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
echo "nodes,exec_time" > ${BASE_DIR}/output/raw/times.csv

for N in "${C_NODES_LIST[@]}"
do
    ## prepare subdirectory
    RUN_DIR=${SCRATCH}/workspace/run_$(now)/n_${N}
    mkdir -p ${RUN_DIR}
    PARTICLE_NO=$((C_PRIMARIES/N))

    echo "Generating run: (P=${PARTICLE_NO}, N=${N}, DIR=${RUN_DIR})"

    ## start measuring time
    T_START=$(timestamp)

    ## generate jobs
    generatemc -p ${PARTICLE_NO} -j ${N} ${BASE_DIR}/input/data/ --workspace ${RUN_DIR} --scheduler_options "[--time=0:03:59 -A plgccbmc11-cpu]"

    ## run simulation
    run_path=$(find ${RUN_DIR}/* -maxdepth 0 -type d)
    sh $run_path/submit.sh
    SED=$(sed -n 9p $run_path/submit.log)
    arrIN=(${SED//;/ })
    COLLECT_ID=$(echo ${arrIN[2]})
    echo "Collect_ID=$COLLECT_ID"

    GET_RESULTS_SH=$PWD/scripts/get_results.sh

    cat << EOF > $GET_RESULTS_SH
#!/bin/bash
#SBATCH --nodes 1
#SBATCH --ntasks 1
#SBATCH --time=00:00:59
#SBATCH -A plgccbmc11-cpu

SACCT_RESULT="\$(sacct -j $COLLECT_ID --format State,End)"
echo \$SACCT_RESULT
arrIN=(\${SACCT_RESULT//;/ })
STATE=\$(echo \${arrIN[4]})
if [[ "\$STATE" == "COMPLETED" ]]
then
    END=\$(echo \${arrIN[5]})
    T_END=\$(date --date="\$END" +"%s%N")
    break
elif [[ "\$STATE" == "FAILED" ]]
then
    echo "Experiment failed, exiting..."
    exit 1
fi

T_EXEC_SECS=\$(( (T_END - $T_START) / 1000000000 ))
T_EXEC_NANS=\$(( (T_END - $T_START) % 1000000000 ))

echo "Run with ${N} nodes took: \${T_EXEC_SECS}s \${T_EXEC_NANS}ns"
echo ""
printf "%d.%09d" \${T_EXEC_SECS} \${T_EXEC_NANS} > ${RUN_DIR}/time.txt
echo "${N},\$(cat ${RUN_DIR}/time.txt)" >> ${BASE_DIR}/output/raw/times.csv

rm -rf $run_path
EOF
    sbatch --dependency=afterok:$COLLECT_ID $GET_RESULTS_SH
done

## generate plot
# python ${PWD}/scripts/plot.py ${BASE_DIR}/output/raw/times.csv ${BASE_DIR}/output/aggregates/image.png

## clean-up

