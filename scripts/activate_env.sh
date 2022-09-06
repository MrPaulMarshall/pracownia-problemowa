#!/bin/bash

if [[ ":$PATH:" != *":$PLG_GROUPS_STORAGE/plggccbmc:${ROOT_PP}/bin"* ]]; then
    export PATH="$PATH:$PLG_GROUPS_STORAGE/plggccbmc:${ROOT_PP}/bin"
fi

module load gcc/11.3.0
