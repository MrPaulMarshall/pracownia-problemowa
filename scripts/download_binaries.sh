#!/bin/bash

BIN_DIR=${ROOT_PP}/bin
GENERATEMC_VERSION=0.6.2
CONVERTMC_VERSION=2.1.0

mkdir ${BIN_DIR} -p

wget -c -x -O ${BIN_DIR}/generatemc https://github.com/DataMedSci/mcpartools/releases/download/v${GENERATEMC_VERSION}/generatemc
wget -c -x -O ${BIN_DIR}/convertmc https://github.com/DataMedSci/pymchelper/releases/download/v${CONVERTMC_VERSION}/convertmc

chmod 750 ${BIN_DIR}/generatemc
chmod 750 ${BIN_DIR}/convertmc
