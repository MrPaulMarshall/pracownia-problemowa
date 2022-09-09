#!/bin/bash
#SBATCH --nodes 1
#SBATCH --ntasks 1
#SBATCH --time=00:00:59
#SBATCH -A plgccbmc11-cpu

## read config
source ${BASE_DIR}/input/config.txt
source ${ROOT_PP}/scripts/activate_env.sh

## prepare subdirectory
RUN_DIR=${BASE_DIR}/workspace/n_${N}
mkdir -p ${RUN_DIR}
mkdir -p ${BASE_DIR}/output/n_${N}
PARTICLE_NO=$(( C_PRIMARIES/N ))

echo "Generating run: (P=${PARTICLE_NO}, N=${N}, DIR=${RUN_DIR})"

## start measuring time
T_START=$(date +"%s%N")

## generate jobs
generatemc -p ${PARTICLE_NO} -j ${N} ${BASE_DIR}/input/data/ --workspace ${RUN_DIR} --scheduler_options "[--time=0:09:59 -A plgccbmc11-cpu]"

## run simulation
run_path=$(find ${RUN_DIR}/* -maxdepth 0 -type d)
ssh -i ${HOME}/.ssh/sbatching ${USER}@ares.cyfronet.pl "source ${ROOT_PP}/scripts/activate_env.sh; sh $run_path/submit.sh"
SED=$(sed -n 9p $run_path/submit.log)
arrIN=(${SED//;/ })
COLLECT_ID=$(echo ${arrIN[2]})
echo "Collect_ID=$COLLECT_ID"
if [[ $COLLECT_ID == "Batch" ]]
then
    mkdir -p ${BASE_DIR}/log/n_${N}/
    cp $run_path/submit.log ${BASE_DIR}/log/n_${N}/
    exit 1
fi

MERGE_RESULTS_SH=${RUN_DIR}/merge_results.sh

cat << EOF > $MERGE_RESULTS_SH
#!/bin/bash
#SBATCH --nodes 12
#SBATCH --ntasks 12
#SBATCH --time=00:39:59
#SBATCH -A plgccbmc11-cpu

while true
do
    SACCT_RESULT="\$(sacct -j $COLLECT_ID --format State,End)"
    echo \$SACCT_RESULT
    arrIN=(\${SACCT_RESULT//;/ })
    STATE=\$(echo \${arrIN[4]})
    if [[ "\$STATE" == "COMPLETED" ]]
    then
        END=\$(echo \${arrIN[5]})
        T_END_EXEC=\$(date --date="\$END" +"%s%N")

        echo \"T_START = $T_START\"
        echo \"T_END_EXEC   = \$T_END_EXEC\"
        T_EXEC_SECS=\$(( (T_END_EXEC - $T_START) / 1000000000 ))
        T_EXEC_NANS=\$(( (T_END_EXEC - $T_START) % 1000000000 ))

        echo "Run with ${N} nodes took: \${T_EXEC_SECS}s \${T_EXEC_NANS}ns"
        echo ""
        echo "Start merging"

        ${ROOT_PP}/bin/convertmc plotdata --many "$run_path/output/*.bdo" ${BASE_DIR}/output/n_${N}

        T_END_MERGE=\$(date +"%s%N")
        T_MERGE_SECS=\$(( (T_END_MERGE - T_END_EXEC) / 1000000000 ))
        T_MERGE_NANS=\$(( (T_END_MERGE - T_END_EXEC) % 1000000000 ))

        printf "%d.%09d,%d.%09d" \${T_EXEC_SECS} \${T_EXEC_NANS} \${T_MERGE_SECS} \${T_MERGE_NANS} > ${RUN_DIR}/time.txt
        echo "${N},\$(cat ${RUN_DIR}/time.txt)" >> ${BASE_DIR}/output/raw/times_${C_PRIMARIES}.csv

        rm -rf $run_path
        exit 0
    elif [[ "\$STATE" == "FAILED" ]]
    then
        echo "Experiment failed for N=${N}, exiting..."
        exit 1
    else
        echo "Waiting for task to finish - I was started too quickly"
    fi
    sleep 0.1
done
EOF

SLURM_LOG=${BASE_DIR}/log/slurm/%j.out

MERGE_RESULTS_ID=$(ssh -i $HOME/.ssh/sbatching ${USER}@ares.cyfronet.pl \
                "sbatch -o ${SLURM_LOG} -e ${SLURM_LOG} --dependency=afterok:$COLLECT_ID $MERGE_RESULTS_SH" | cut -d " " -f 4)
echo "MERGE_RESULTS_ID=$MERGE_RESULTS_ID"

## Run simulation for next number of nodes or collect final results
N=$(( N * NODES_INC ))

if (( "$N" <= "$NODES_MAX" ))
then
    echo "Sumbitting next job, N=${N}"
    ssh -i $HOME/.ssh/sbatching ${USER}@ares.cyfronet.pl \
            "ROOT_PP=${ROOT_PP} BASE_DIR=${BASE_DIR} N=${N} sbatch -o ${SLURM_LOG} -e ${SLURM_LOG} --dependency=afterok:$MERGE_RESULTS_ID ${ROOT_PP}/scripts/run_experiment.sh"
else
    echo "Sumbitting final job - plot"
    ssh -i $HOME/.ssh/sbatching ${USER}@ares.cyfronet.pl \
            "ROOT_PP=${ROOT_PP} BASE_DIR=${BASE_DIR} sbatch -o ${SLURM_LOG} -e ${SLURM_LOG} --dependency=afterok:$MERGE_RESULTS_ID ${ROOT_PP}/scripts/draw_plot.sh"
fi
