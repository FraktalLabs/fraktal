#!/bin/bash
#
# Run code to test sol contracts on a fraktal node
#
# TODO: Contract return values check

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
GO_ETHEREUM_DIR="${SCRIPT_DIR}/../../../go-ethereum/"
SOLIDITY_DIR="${SCRIPT_DIR}/../../../solidity/"
SEQUENCER_ADDRESS=$(cat ~/fraktal-data/keystore/UTC* | jq -r '.address')

# Kill any running fraktal nodes
pkill -f geth

FRAKTAL_OUTPUT="${SCRIPT_DIR}/fraktal.log"
rm -f $FRAKTAL_OUTPUT
${SCRIPT_DIR}/../../../scripts/run-fraktal.sh > $FRAKTAL_OUTPUT 2>&1 &

sleep 5

#TODO: Check ABI
# Build the Yul-Yield solidity test contract
YUL_YIELD_CONTRACT="${SCRIPT_DIR}/../sol/yul-yield.sol"
YUL_YIELD_BYTECODE=$(${SOLIDITY_DIR}/build/solc/solc --bin ${YUL_YIELD_CONTRACT} | tail -n 1)
echo "Yul Yield sol contract built, bytecode: ${YUL_YIELD_BYTECODE}"

# Deploy Yul-Yield contract to fraktal node
RPC="localhost:8545"
JSON='
{
  "jsonrpc": "2.0",
  "method": "eth_sendTransaction",
  "params": [{
    "from": "0x'$SEQUENCER_ADDRESS'",
    "data": "'0x$YUL_YIELD_BYTECODE'"
  }],
  "id": 1
}
'

TMP_SEND_TX=$SCRIPT_DIR/sendTx.json
echo $JSON > $TMP_SEND_TX

RES=$(curl -H "Content-Type: application/json" -X POST --data @$TMP_SEND_TX $RPC | jq -r '.result')

echo TX HASH SENT : $RES
echo GETTING TX Receipt :

sleep 2

JSON='
{
  "jsonrpc": "2.0",
  "method": "eth_getTransactionReceipt",
  "params": ["'$RES'"],
  "id": 1
}
'

echo $JSON > $TMP_SEND_TX

RES=$(curl -H "Content-Type: application/json" -X POST --data @$TMP_SEND_TX $RPC | jq -r '.result')
YUL_YIELD_CONTRACT_ADDRESS=$(echo $RES | jq -r '.contractAddress')
echo "Deployed yul-yield.sol to a fraktal node at contract address : " $YUL_YIELD_CONTRACT_ADDRESS

# Call main() function
FUNC_SIG=$(cast sig 'main()')
YUL_YIELD_CALL_RECEIPT=$(FUNC_SIG=${FUNC_SIG} CONTRACT_ADDRESS=${YUL_YIELD_CONTRACT_ADDRESS} SEQUENCER_ADDRESS=${SEQUENCER_ADDRESS} ${SCRIPT_DIR}/../../../scripts/call-contract.sh)
YUL_YIELD_NODE_OUT=$(cat $FRAKTAL_OUTPUT | grep 'opMstore')

pkill -f geth

sleep 2

rm -f $FRAKTAL_OUTPUT
${SCRIPT_DIR}/../../../scripts/run-fraktal.sh > $FRAKTAL_OUTPUT 2>&1 &

sleep 5

YIELD_CONTRACT="${SCRIPT_DIR}/../sol/yield.sol"
YIELD_BYTECODE=$(${SOLIDITY_DIR}/build/solc/solc --bin ${YIELD_CONTRACT} | tail -n 1)
echo "Yield sol contract built, bytecode: ${YIELD_BYTECODE}"

# Deploy Yield contract to fraktal node
RPC="localhost:8545"
JSON='
{
  "jsonrpc": "2.0",
  "method": "eth_sendTransaction",
  "params": [{
    "from": "0x'$SEQUENCER_ADDRESS'",
    "data": "'0x$YIELD_BYTECODE'"
  }],
  "id": 1
}
'

echo $JSON > $TMP_SEND_TX

RES=$(curl -H "Content-Type: application/json" -X POST --data @$TMP_SEND_TX $RPC | jq -r '.result')

echo TX HASH SENT : $RES
echo GETTING TX Receipt :

sleep 2

JSON='
{
  "jsonrpc": "2.0",
  "method": "eth_getTransactionReceipt",
  "params": ["'$RES'"],
  "id": 1
}
'

echo $JSON > $TMP_SEND_TX

RES=$(curl -H "Content-Type: application/json" -X POST --data @$TMP_SEND_TX $RPC | jq -r '.result')
YIELD_CONTRACT_ADDRESS=$(echo $RES | jq -r '.contractAddress')
echo "Deployed yul-yield.sol to a fraktal node at contract address : " $YIELD_CONTRACT_ADDRESS

FUNC_SIG=$(cast sig 'main()')
YIELD_CALL_RECEIPT=$(FUNC_SIG=${FUNC_SIG} CONTRACT_ADDRESS=${YIELD_CONTRACT_ADDRESS} SEQUENCER_ADDRESS=${SEQUENCER_ADDRESS} ${SCRIPT_DIR}/../../../scripts/call-contract.sh)
YIELD_NODE_OUT=$(cat $FRAKTAL_OUTPUT | grep 'opMstore')

## Strip outputs for comparison
YUL_YIELD_NODE_OUT=$(echo "${YUL_YIELD_NODE_OUT}" | sed -E 's/.*opMstore:/opMstore:/' | tr '\n' ' ')
YIELD_NODE_OUT=$(echo "${YIELD_NODE_OUT}" | sed -E 's/.*opMstore:/opMstore:/' | tr '\n' ' ')
#SPAWN_OUT=$(echo "${SPAWN_OUT}" | sed -E 's/.*opMstore:/opMstore:/' | tr '\n' ' ')

EXPECTED_YUL_YIELD_OUT="opMstore: mStart=\[64 0 0 0\], val=\[128 0 0 0\] opMstore: mStart=\[0 0 0 0\], val=\[66 0 0 0\] opMstore: mStart=\[0 0 0 0\], val=\[67 0 0 0\] opMstore: mStart=\[128 0 0 0\], val=\[66 0 0 0\]"
EXPECTED_YIELD_OUT="opMstore: mStart=\[64 0 0 0\], val=\[128 0 0 0\] opMstore: mStart=\[0 0 0 0\], val=\[66 0 0 0\] opMstore: mStart=\[0 0 0 0\], val=\[67 0 0 0\] opMstore: mStart=\[0 0 0 0\], val=\[50 0 0 0\] opMstore: mStart=\[128 0 0 0\], val=\[50 0 0 0\] opMstore: mStart=\[128 0 0 0\], val=\[66 0 0 0\]"
#EXPECTED_SPAWN_OUT="opMstore: mStart=\[128 0 0 0\], val=\[66 0 0 0\] opMstore: mStart=\[160 0 0 0\], val=\[50 0 0 0\] 0x00000000000000000000000000000000000000000000000000000000000000420000000000000000000000000000000000000000000000000000000000000032"
#
echo ""
echo "=========================================================================="
echo "=========================================================================="
echo ""
echo "Tests :"
echo ""
#echo "Checking Yield contract bytecode segment '6042608052fc603260a052' : " $(echo "${YIELD_BYTECODE}" | grep -q "6042608052fc603260a052" && echo "PASS" || echo "FAIL")
echo "Checking Yul-Yield contract output : " $(echo "${YUL_YIELD_NODE_OUT}" | grep -qz "${EXPECTED_YUL_YIELD_OUT}" && echo "PASS" || echo "FAIL")
echo "Checking Yield contract output : " $(echo "${YIELD_NODE_OUT}" | grep -qz "${EXPECTED_YIELD_OUT}" && echo "PASS" || echo "FAIL")
#echo "Checking Spawn contract bytecode segment '5b602e6032600afb505060206003565b5' : " $(echo "${SPAWN_BYTECODE}" | grep -q "5b602e6032600afb505060206003565b5" && echo "PASS" || echo "FAIL")
#echo "Checking Spawn contract output : " $(echo "${SPAWN_OUT}" | grep -qz "${EXPECTED_SPAWN_OUT}" && echo "PASS" || echo "FAIL")
#TODO: Check receipt logs for data, order?, check fraktal.log for mstore
