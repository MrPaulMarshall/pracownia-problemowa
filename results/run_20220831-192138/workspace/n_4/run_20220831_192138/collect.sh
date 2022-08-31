#!/usr/bin/env bash

# Exit immediately if a simple command exits with a non-zero status.
set -e

INPUT_WILDCARD=/net/people/plgrid/plgpitrus/pracownia-problemowa/results/run_20220831-192138/workspace/n_4/run_20220831_192138/workspace/job_*/*.bdo
OUTPUT_DIRECTORY=/net/people/plgrid/plgpitrus/pracownia-problemowa/results/run_20220831-192138/workspace/n_4/run_20220831_192138/output

# change working directory
cd /net/people/plgrid/plgpitrus/pracownia-problemowa/results/run_20220831-192138/workspace/n_4/run_20220831_192138

# make output folder
mkdir -p $OUTPUT_DIRECTORY

TRANSPORT_COMMAND=mv
for INPUT_FILE in $INPUT_WILDCARD; do
  $TRANSPORT_COMMAND $INPUT_FILE $OUTPUT_DIRECTORY
done