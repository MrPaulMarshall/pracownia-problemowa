#!/bin/bash

ROOT=${HOME}/pracownia-problemowa

## define utilities
now() { # get the current date-time in YYYYMMDD-HHMMSS format
    date +"%Y%m%d-%H%M%S"
}

## parse config
source ${ROOT}/input/config.txt

## download binaries
if [[ -f ${ROOT}/bin/generatemc && -f ${ROOT}/bin/convertmc ]]; then
    echo "Binaries already present (generatemc: v$(${ROOT}/bin/generatemc --version), convertmc: v$(${ROOT}/bin/convertmc --version))"
else
    ROOT=${ROOT} ${ROOT}/scripts/download_binaries.sh
fi

## activate env
source ${ROOT}/scripts/activate_env.sh
echo ""

## create directories -- TODO: maybe structure needs changes
BASE_DIR=${ROOT}/results/experiment_$(now)
mkdir -p ${BASE_DIR}/input/data
mkdir -p ${BASE_DIR}/log
mkdir -p ${BASE_DIR}/output/raw ${BASE_DIR}/output/aggregates
mkdir -p ${BASE_DIR}/workspace

## copy input data, if missing resort to defaults
cp ${ROOT}/input/config.txt ${BASE_DIR}/input/

for NAME in beam detect geo mat
do
    if [ -f ${ROOT}/input/data/$NAME.dat ]; then
        cp ${ROOT}/input/data/$NAME.dat ${BASE_DIR}/input/data/
    else
        cp ${ROOT}/input/default/$NAME.dat ${BASE_DIR}/input/data/
    fi
done

## prepare and run simulation for each number of nodes
echo "nodes,exec_time" > ${BASE_DIR}/output/raw/times.csv

## sbatch run_experiment.sh
ROOT=${ROOT} BASE_DIR=${BASE_DIR} N=${NODES_MIN} sbatch ${ROOT}/scripts/run_experiment.sh
