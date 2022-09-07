#!/bin/bash

ROOT_PP=${HOME}/pracownia-problemowa

## define utilities
now() { # get the current date-time in YYYYMMDD-HHMMSS format
    date +"%Y%m%d-%H%M%S"
}

## parse config
source ${ROOT_PP}/input/config.txt

## download binaries
if [[ -f ${ROOT_PP}/bin/generatemc && -f ${ROOT_PP}/bin/convertmc ]]; then
    echo "Binaries already present (generatemc: v$(${ROOT_PP}/bin/generatemc --version), convertmc: v$(${ROOT_PP}/bin/convertmc --version))"
else
    ROOT_PP=${ROOT_PP} ${ROOT_PP}/scripts/download_binaries.sh
fi

## activate env
source ${ROOT_PP}/scripts/activate_env.sh
echo ""

## create directories -- TODO: maybe structure needs changes
BASE_DIR=${SCRATCH}/pp/results/experiment_$(now)
mkdir -p ${BASE_DIR}/input/data
mkdir -p ${BASE_DIR}/log/slurm
mkdir -p ${BASE_DIR}/output/raw ${BASE_DIR}/output/aggregates
mkdir -p ${BASE_DIR}/workspace

## copy input data, if missing resort to defaults
cp ${ROOT_PP}/input/config.txt ${BASE_DIR}/input/

for NAME in beam detect geo mat
do
    if [ -f ${ROOT_PP}/input/data/$NAME.dat ]; then
        cp ${ROOT_PP}/input/data/$NAME.dat ${BASE_DIR}/input/data/
    else
        cp ${ROOT_PP}/input/default/$NAME.dat ${BASE_DIR}/input/data/
    fi
done

## prepare and run simulation for each number of nodes
echo "nodes,exec_time" > ${BASE_DIR}/output/raw/times_${C_PRIMARIES}.csv

## sbatch run_experiment.sh
SLURM_LOG=${BASE_DIR}/log/slurm/%j.out
ROOT_PP=${ROOT_PP} BASE_DIR=${BASE_DIR} N=${NODES_MIN} sbatch -o ${SLURM_LOG} -e ${SLURM_LOG} ${ROOT_PP}/scripts/run_experiment.sh
