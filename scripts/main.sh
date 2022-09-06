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

## sbatch run_experiment.sh
BASE_DIR=${BASE_DIR} N=${NODES_MIN} sbatch ${PWD}/scripts/run_experiment.sh
