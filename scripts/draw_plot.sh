#!/bin/bash
#SBATCH --nodes 1
#SBATCH --ntasks 1
#SBATCH --time=00:00:59
#SBATCH -A plgccbmc11-cpu

# load python and libraries
module load .plgrid
module load plgrid/libs/python-numpy/2020.03-intel-2020a-python-3.8.2
module load matplotlib

# read config
source ${BASE_DIR}/input/config.txt

# draw plot
python ${ROOT_PP}/scripts/plot.py ${BASE_DIR}/output/raw/times_${C_PRIMARIES}.csv ${BASE_DIR}/output/aggregates/plot_${C_PRIMARIES}.png
