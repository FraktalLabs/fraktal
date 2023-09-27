#!/bin/bash
#
# Deploy a contract to the blockchain over RPC using bytecode

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Deploy Yul-Yield contract to fraktal node
RPC="localhost:8545"
JSON='
{
  "jsonrpc": "2.0",
  "method": "eth_sendTransaction",
  "params": [{
    "from": "0x'$SEQUENCER_ADDRESS'",
    "data": "0x'$CONTRACT_BYTECODE'"
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
CONTRACT_ADDRESS=$(echo $RES | jq -r '.contractAddress')
echo "Deployed contract at address : $CONTRACT_ADDRESS"
echo $CONTRACT_ADDRESS

rm $TMP_SEND_TX
