#!/bin/bash
#SBATCH --nodes 1
#SBATCH --ntasks 1
#SBATCH --time=00:00:59
#SBATCH -A plgccbmc11-cpu

## read config
source ${BASE_DIR}/input/config.txt

## prepare subdirectory
RUN_DIR=${BASE_DIR}/workspace/n_${N}
mkdir -p ${RUN_DIR}
PARTICLE_NO=$(( C_PRIMARIES/N ))

echo "Generating run: (P=${PARTICLE_NO}, N=${N}, DIR=${RUN_DIR})"

## start measuring time
T_START=$(date +"%s%N")

## generate jobs
generatemc -p ${PARTICLE_NO} -j ${N} ${BASE_DIR}/input/data/ --workspace ${RUN_DIR} --scheduler_options "[--time=0:03:59 -A plgccbmc11-cpu]"

## run simulation
run_path=$(find ${RUN_DIR}/* -maxdepth 0 -type d)
ssh ${USER}@ares.cyfronet.pl "sh $run_path/submit.sh"
SED=$(sed -n 9p $run_path/submit.log)
arrIN=(${SED//;/ })
COLLECT_ID=$(echo ${arrIN[2]})
echo "Collect_ID=$COLLECT_ID"

GET_RESULTS_SH=${RUN_DIR}/get_results.sh

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

GET_RESULTS_ID=$(ssh ${USER}@ares.cyfronet.pl "sbatch --dependency=afterok:$COLLECT_ID $GET_RESULTS_SH | cut -d \" \" -f 4")

## Run simulation for next number of nodes or collect final results
N=$(( N * NODES_INC ))

if (( "$N" <= "$NODES_MAX" ))
then
    ssh ${USER}@ares.cyfronet.pl "ROOT=${ROOT} BASE_DIR=${BASE_DIR} N=${N} sbatch --dependency=afterok:$GET_RESULTS_ID ${ROOT}/scripts/run_experiment.sh"
else
    ssh ${USER}@ares.cyfronet.pl "ROOT=${ROOT} BASE_DIR=${BASE_DIR} sbatch --dependency=afterok:$GET_RESULTS_ID ${ROOT}/scripts/draw_plot.sh"
fi
