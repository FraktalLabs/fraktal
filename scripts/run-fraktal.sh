#!/bin/bash
#
# Run Fraktal node

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
WORK_DIR=$SCRIPT_DIR/..

ETH_PRIV_SCRIPTS=$HOME/workspace/blockchain/MyBlockchains/eth-private-network/scripts/

# Start Fraktal node
$ETH_PRIV_SCRIPTS/run-miner.sh -d $HOME/fraktal-data/ -x -G ${WORK_DIR}/go-ethereum/build/bin/geth
