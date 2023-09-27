#!/bin/bash
#
# Run Fraktal node

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
WORK_DIR=$SCRIPT_DIR/..

ETH_PRIV_SCRIPTS=$HOME/workspace/blockchain/MyBlockchains/eth-private-network/scripts/

# Kill any running fraktal nodes
pkill -f geth

# Start Fraktal node
if [ -z $FRAKTAL_OUTPUT ]; then
  $ETH_PRIV_SCRIPTS/run-miner.sh -d $HOME/fraktal-data/ -x -G ${WORK_DIR}/go-ethereum/build/bin/geth
else
  $ETH_PRIV_SCRIPTS/run-miner.sh -d $HOME/fraktal-data/ -x -G ${WORK_DIR}/go-ethereum/build/bin/geth > $FRAKTAL_OUTPUT 2>&1 &
fi
