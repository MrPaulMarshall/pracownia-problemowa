#!/bin/bash
#SBATCH --nodes 1
#SBATCH --ntasks 1
#SBATCH --time=00:00:59
#SBATCH -A plgccbmc11-cpu

# load python and libraries
source ${ROOT_PP}/scripts/activate_python.sh

# read config
source ${BASE_DIR}/input/config.txt

# draw plot
python ${ROOT_PP}/scripts/plot.py ${BASE_DIR}/output/raw/times_${C_PRIMARIES}.csv \
        ${BASE_DIR}/output/aggregates/plot_${C_PRIMARIES}.png ${C_PRIMARIES}
