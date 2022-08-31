#!/usr/bin/env bash
# Exit immediately if a simple command exits with a non-zero status.
set -e

# no user options provided

# Run individual jobs
/net/people/plgrid/plgpitrus/pracownia-problemowa/results/run_20220831-192138/workspace/n_4/run_20220831_192138/workspace/job_`printf %04d $SLURM_ARRAY_TASK_ID`/run.sh
