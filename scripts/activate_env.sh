#!/bin/bash

echo "Appending to PATH..."
export PATH="$PATH:$PLG_GROUPS_STORAGE/plggccbmc:$PWD/bin"

echo "Loading modules..."
module load gcc/11.3.0
