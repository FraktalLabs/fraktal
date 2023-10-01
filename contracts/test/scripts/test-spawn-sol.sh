#!/bin/bash
#
# Run code to test sol contracts on a fraktal node
#
# TODO: Contract return values check
# TODO: Check ABI

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
GO_ETHEREUM_DIR="${SCRIPT_DIR}/../../../go-ethereum/"
SOLIDITY_DIR="${SCRIPT_DIR}/../../../solidity/"
SEQUENCER_ADDRESS=$(cat ~/fraktal-data/keystore/UTC* | jq -r '.address')

FRAKTAL_OUTPUT=${SCRIPT_DIR}/fraktal.log
FRAKTAL_OUTPUT=${FRAKTAL_OUTPUT} ${SCRIPT_DIR}/../../../scripts/run-fraktal.sh
sleep 5

# Build the Yul-Spawn solidity test contract
YUL_SPAWN_CONTRACT="${SCRIPT_DIR}/../sol/yul-spawn.sol"
YUL_SPAWN_BYTECODE=$(${SOLIDITY_DIR}/build/solc/solc --bin ${YUL_SPAWN_CONTRACT} | tail -n 1)
echo "Yul-Spawn sol contract built, bytecode: ${YUL_SPAWN_BYTECODE}"

YUL_SPAWN_CONTRACT_ADDRESS=$(SEQUENCER_ADDRESS=${SEQUENCER_ADDRESS} CONTRACT_BYTECODE=${YUL_SPAWN_BYTECODE} ${SCRIPT_DIR}/../../scripts/deploy-contract.sh | tail -n 1)
echo "Deployed yul-spawn.sol to a fraktal node at contract address : " $YUL_SPAWN_CONTRACT_ADDRESS

# Call main() function
FUNC_SIG=$(cast sig 'main()')
YUL_SPAWN_CALL_RECEIPT=$(FUNC_SIG=${FUNC_SIG} CONTRACT_ADDRESS=${YUL_SPAWN_CONTRACT_ADDRESS} SEQUENCER_ADDRESS=${SEQUENCER_ADDRESS} ${SCRIPT_DIR}/../../scripts/call-contract.sh)
YUL_SPAWN_NODE_OUT=$(cat $FRAKTAL_OUTPUT | grep 'opMstore')

# Build the Spawn solidity test contract
SPAWN_CONTRACT="${SCRIPT_DIR}/../sol/spawn.sol"
SPAWN_BYTECODE=$(${SOLIDITY_DIR}/build/solc/solc --bin ${SPAWN_CONTRACT} | tail -n 1)
echo "Spawn sol contract built, bytecode: ${SPAWN_BYTECODE}"

SPAWN_CONTRACT_ADDRESS=$(SEQUENCER_ADDRESS=${SEQUENCER_ADDRESS} CONTRACT_BYTECODE=${SPAWN_BYTECODE} ${SCRIPT_DIR}/../../scripts/deploy-contract.sh | tail -n 1)
echo "Deployed yul-spawn.sol to a fraktal node at contract address : " $SPAWN_CONTRACT_ADDRESS

# Call main() function
SPAWN_CALL_RECEIPT=$(FUNC_SIG=${FUNC_SIG} CONTRACT_ADDRESS=${SPAWN_CONTRACT_ADDRESS} SEQUENCER_ADDRESS=${SEQUENCER_ADDRESS} ${SCRIPT_DIR}/../../scripts/call-contract.sh)
SPAWN_NODE_OUT=$(cat $FRAKTAL_OUTPUT | grep 'opMstore')

### Strip outputs for comparison
YUL_SPAWN_NODE_OUT=$(echo "${YUL_SPAWN_NODE_OUT}" | sed -E 's/.*opMstore:/opMstore:/' | tr '\n' ' ')
SPAWN_NODE_OUT=$(echo "${SPAWN_NODE_OUT}" | sed -E 's/.*opMstore:/opMstore:/' | tr '\n' ' ')

#TODO: Check at line end to prevent false positives
EXPECTED_YUL_SPAWN_OUT="opMstore: mStart=\[64 0 0 0\], val=\[128 0 0 0\] opMstore: mStart=\[0 0 0 0\], val=\[66 0 0 0\] opMstore: mStart=\[0 0 0 0\], val=\[51 0 0 0\] opMstore: mStart=\[0 0 0 0\], val=\[67 0 0 0\] opMstore: mStart=\[128 0 0 0\], val=\[66 0 0 0\] opMstore: mStart=\[0 0 0 0\], val=\[50 0 0 0\]"
EXPECTED_SPAWN_OUT="opMstore: mStart=\[64 0 0 0\], val=\[128 0 0 0\] opMstore: mStart=\[0 0 0 0\], val=\[66 0 0 0\] opMstore: mStart=\[0 0 0 0\], val=\[67 0 0 0\] opMstore: mStart=\[128 0 0 0\], val=\[50 0 0 0\] opMstore: mStart=\[0 0 0 0\], val=\[50 0 0 0\] opMstore: mStart=\[128 0 0 0\], val=\[50 0 0 0\]"

echo ""
echo "=========================================================================="
echo "=========================================================================="
echo ""
echo "Tests :"
echo ""
echo "Checking Yul-Spawn contract bytecode segment '5b605860326044fb5050605a565b005b6033' : " $(echo "${YUL_SPAWN_BYTECODE}" | grep -q "5b605860326044fb5050605a565b005b6033" && echo "PASS" || echo "FAIL")
echo "Checking Yul-Spawn contract output : " $(echo "${YUL_SPAWN_NODE_OUT}" | grep -q "${EXPECTED_YUL_SPAWN_OUT}" && echo "PASS" || echo "FAIL")
echo "Checking Spawn contract bytecode segment '0426000526100ba6032610061fb50506100bc565b005b6043600052' : " $(echo "${SPAWN_BYTECODE}" | grep -q "0426000526100ba6032610061fb50506100bc565b005b6043600052" && echo "PASS" || echo "FAIL")
echo "Checking Spawn contract output : " $(echo "${SPAWN_NODE_OUT}" | grep -q "${EXPECTED_SPAWN_OUT}" && echo "PASS" || echo "FAIL")
#TODO: Check receipt logs for data?

pkill -f geth
rm -f $FRAKTAL_OUTPUT
