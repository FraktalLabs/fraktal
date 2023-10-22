#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

GETH_DIR=${SCRIPT_DIR}/../../go-ethereum/
ABIGEN_BIN=${GETH_DIR}/build/bin/abigen

GO_CONTRACT_DIR=${SCRIPT_DIR}/../go/
PREDEPLOY_GO_DIR=${GO_CONTRACT_DIR}/predeploys/

BUILDS_DIR=${SCRIPT_DIR}/../builds/
PREDEPLOY_BUILDS_DIR=${BUILDS_DIR}/predeploys/

rm -rf $GO_CONTRACT_DIR
mkdir -p $GO_CONTRACT_DIR

# Generate Go contract bindings
mkdir -p $PREDEPLOY_GO_DIR

mkdir -p $PREDEPLOY_GO_DIR/filestore
$ABIGEN_BIN --bin=$PREDEPLOY_BUILDS_DIR/Filestore.bin --abi=$PREDEPLOY_BUILDS_DIR/Filestore.abi --pkg=filestore --out=$PREDEPLOY_GO_DIR/filestore/filestore.go
