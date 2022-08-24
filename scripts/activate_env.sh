#!/bin/bash

echo "Downloading binaries..."
scripts/download_binaries.sh

echo "Appending to PATH..."
export PATH="$PATH:$PLG_GROUPS_STORAGE/plggccbmc:$HOME/pracownia-problemowa/bin"

echo "Loading modules..."
module load gcc/11.3.0

echo "Environment ready"
