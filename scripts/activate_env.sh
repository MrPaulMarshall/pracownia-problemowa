#!/bin/bash

echo "Appending to PATH..."
export PATH="$PATH:$PLG_GROUPS_STORAGE/plggccbmc:$PWD/bin"

echo "Loading modules..."
module load .plgrid
module load plgrid/libs/python-numpy/2020.03-intel-2020a-python-3.8.2
module load matplotlib

module load gcc/11.3.0
