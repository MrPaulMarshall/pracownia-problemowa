#!/usr/bin/env bash

# Exit immediately if a simple command exits with a non-zero status.
set -e

# location of SHIELD-HIT12A binary file
SHIELDHIT_BIN=shieldhit

# working directory, output files will be saved here
WORK_DIR=/net/people/plgrid/plgpitrus/pracownia-problemowa/results/run_20220831-192138/workspace/n_4/run_20220831_192138/workspace/job_0004

# number of particles per job
PARTICLE_NO=250

# seed of RNG
RNG_SEED=4

# main SHIELD-HIT12A input files
BEAM_FILE=/net/people/plgrid/plgpitrus/pracownia-problemowa/results/run_20220831-192138/workspace/n_4/run_20220831_192138/input/beam.dat
GEO_FILE=/net/people/plgrid/plgpitrus/pracownia-problemowa/results/run_20220831-192138/workspace/n_4/run_20220831_192138/input/geo.dat
MAT_FILE=/net/people/plgrid/plgpitrus/pracownia-problemowa/results/run_20220831-192138/workspace/n_4/run_20220831_192138/input/mat.dat
DETECT_FILE=/net/people/plgrid/plgpitrus/pracownia-problemowa/results/run_20220831-192138/workspace/n_4/run_20220831_192138/input/detect.dat

# go to working directory
cd /net/people/plgrid/plgpitrus/pracownia-problemowa/results/run_20220831-192138/workspace/n_4/run_20220831_192138/workspace/job_0004

# execute simulation
$SHIELDHIT_BIN --beamfile=$BEAM_FILE --geofile=$GEO_FILE --matfile=$MAT_FILE --detectfile=$DETECT_FILE -n $PARTICLE_NO -N $RNG_SEED  $WORK_DIR

