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

# Build the Yul-Yield solidity test contract
YUL_YIELD_CONTRACT="${SCRIPT_DIR}/../sol/yul-yield.sol"
YUL_YIELD_BYTECODE=$(${SOLIDITY_DIR}/build/solc/solc --bin ${YUL_YIELD_CONTRACT} | tail -n 1)
echo "Yul Yield sol contract built, bytecode: ${YUL_YIELD_BYTECODE}"

YUL_YIELD_CONTRACT_ADDRESS=$(SEQUENCER_ADDRESS=${SEQUENCER_ADDRESS} CONTRACT_BYTECODE=${YUL_YIELD_BYTECODE} ${SCRIPT_DIR}/../../scripts/deploy-contract.sh | tail -n 1)
echo "Deployed yul-yield.sol to a fraktal node at contract address : " $YUL_YIELD_CONTRACT_ADDRESS

# Call main() function
FUNC_SIG=$(cast sig 'main()')
YUL_YIELD_CALL_RECEIPT=$(FUNC_SIG=${FUNC_SIG} CONTRACT_ADDRESS=${YUL_YIELD_CONTRACT_ADDRESS} SEQUENCER_ADDRESS=${SEQUENCER_ADDRESS} ${SCRIPT_DIR}/../../scripts/call-contract.sh)
YUL_YIELD_NODE_OUT=$(cat $FRAKTAL_OUTPUT | grep 'opMstore')

FRAKTAL_OUTPUT=${FRAKTAL_OUTPUT} ${SCRIPT_DIR}/../../../scripts/run-fraktal.sh
sleep 5

YIELD_CONTRACT="${SCRIPT_DIR}/../sol/yield.sol"
YIELD_BYTECODE=$(${SOLIDITY_DIR}/build/solc/solc --bin ${YIELD_CONTRACT} | tail -n 1)
echo "Yield sol contract built, bytecode: ${YIELD_BYTECODE}"

YIELD_CONTRACT_ADDRESS=$(SEQUENCER_ADDRESS=${SEQUENCER_ADDRESS} CONTRACT_BYTECODE=${YIELD_BYTECODE} ${SCRIPT_DIR}/../../scripts/deploy-contract.sh | tail -n 1)
echo "Deployed yield.sol to a fraktal node at contract address : " $YIELD_CONTRACT_ADDRESS

YIELD_CALL_RECEIPT=$(FUNC_SIG=${FUNC_SIG} CONTRACT_ADDRESS=${YIELD_CONTRACT_ADDRESS} SEQUENCER_ADDRESS=${SEQUENCER_ADDRESS} ${SCRIPT_DIR}/../../scripts/call-contract.sh)
YIELD_NODE_OUT=$(cat $FRAKTAL_OUTPUT | grep 'opMstore')

## Strip outputs for comparison
YUL_YIELD_NODE_OUT=$(echo "${YUL_YIELD_NODE_OUT}" | sed -E 's/.*opMstore:/opMstore:/' | tr '\n' ' ')
YIELD_NODE_OUT=$(echo "${YIELD_NODE_OUT}" | sed -E 's/.*opMstore:/opMstore:/' | tr '\n' ' ')

EXPECTED_YUL_YIELD_OUT="opMstore: mStart=\[64 0 0 0\], val=\[128 0 0 0\] opMstore: mStart=\[0 0 0 0\], val=\[66 0 0 0\] opMstore: mStart=\[0 0 0 0\], val=\[67 0 0 0\] opMstore: mStart=\[128 0 0 0\], val=\[66 0 0 0\]"
EXPECTED_YIELD_OUT="opMstore: mStart=\[64 0 0 0\], val=\[128 0 0 0\] opMstore: mStart=\[0 0 0 0\], val=\[66 0 0 0\] opMstore: mStart=\[0 0 0 0\], val=\[67 0 0 0\] opMstore: mStart=\[0 0 0 0\], val=\[50 0 0 0\] opMstore: mStart=\[128 0 0 0\], val=\[50 0 0 0\] opMstore: mStart=\[128 0 0 0\], val=\[66 0 0 0\]"

echo ""
echo "=========================================================================="
echo "=========================================================================="
echo ""
echo "Tests :"
echo ""
echo "Checking Yul-Yield contract bytecode segment '6042600052fc6043600052' : " $(echo "${YUL_YIELD_BYTECODE}" | grep -q "6042600052fc6043600052" && echo "PASS" || echo "FAIL")
echo "Checking Yul-Yield contract output : " $(echo "${YUL_YIELD_NODE_OUT}" | grep -qz "${EXPECTED_YUL_YIELD_OUT}" && echo "PASS" || echo "FAIL")
echo "Checking Yield contract bytecode segment '6042600052fc6043600052' : " $(echo "${YIELD_BYTECODE}" | grep -q "6042600052fc6043600052" && echo "PASS" || echo "FAIL")
echo "Checking Yield contract output : " $(echo "${YIELD_NODE_OUT}" | grep -qz "${EXPECTED_YIELD_OUT}" && echo "PASS" || echo "FAIL")
#TODO: Check receipt logs for data?

pkill -f geth
rm -f $FRAKTAL_OUTPUT
