#!/bin/bash

RPC="localhost:8545"

JSON='
{
  "jsonrpc": "2.0",
  "method": "eth_sendTransaction",
  "params": [{
    "from": "0x'$SEQUENCER_ADDRESS'",
    "to": "'$CONTRACT_ADDRESS'",
    "data": "'$FUNC_SIG'"
  }],
  "id": 1
}
'

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
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

echo $RES | jq -r '.'
