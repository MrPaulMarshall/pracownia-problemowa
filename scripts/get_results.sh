#!/bin/bash
#SBATCH --nodes 1
#SBATCH --ntasks 1
#SBATCH --time=00:00:59
#SBATCH -A plgccbmc11-cpu

SACCT_RESULT="$(sacct -j 647823 --format State,End)"
echo $SACCT_RESULT
arrIN=(${SACCT_RESULT//;/ })
STATE=$(echo ${arrIN[4]})
if [[ "$STATE" == "COMPLETED" ]]
then
    END=$(echo ${arrIN[5]})
    T_END=$(date --date="$END" +"%s%N")
    break
elif [[ "$STATE" == "FAILED" ]]
then
    echo "Experiment failed, exiting..."
    exit 1
fi

T_EXEC_SECS=$(( (T_END - 1662477398549047842) / 1000000000 ))
T_EXEC_NANS=$(( (T_END - 1662477398549047842) % 1000000000 ))

echo "Run with 100 nodes took: ${T_EXEC_SECS}s ${T_EXEC_NANS}ns"
echo ""
printf "%d.%09d" ${T_EXEC_SECS} ${T_EXEC_NANS} > /net/ascratch/people/plgpitrus/workspace/run_20220906-171638/n_100/time.txt
echo "100,$(cat /net/ascratch/people/plgpitrus/workspace/run_20220906-171638/n_100/time.txt)" >> /net/people/plgrid/plgpitrus/pracownia-problemowa/results/run_20220906-171638/output/raw/times.csv

rm -rf /net/ascratch/people/plgpitrus/workspace/run_20220906-171638/n_100/run_20220906_171638
