#!/bin/bash
#
# This script launches a fraktal node ( Clique POA agent )

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
WORK_DIR=$SCRIPT_DIR/..

STATE_RESET=0

# Defaults give theoretical max throughput of 1800 TPS = ~15 tx/sec ( mainnet ) X 12 X 10
CHAIN_ID=505
PERIOD=1 # 1 second per block ( 12x faster than Ethereum mainnet )
GAS_LIMIT=300000000 # 300M gas limit ( 10x Ethereum mainnet )
FEES=false # Include london fork fees in network

PEER_PORT=30303
HTTP_PORT=8545
GETH_BIN=$WORK_DIR/go-ethereum/build/bin/geth

display_help() {
  echo "Usage: $0 -d <data_dir> [options]"
  echo
  echo "   -h, --help                 show help"
  echo "   -d, --data                 Geth node data dir (required)"
  echo "   -x, --clear                Clear & Reset data dir before starting"
  echo "   -G, --geth                 Geth binary path ( default: $WORK_DIR/go-ethereum/build/bin/geth )"

  echo "   -c, --chain-id             Chain ID"
  echo "   -p, --period               Block period ( in seconds )"
  echo "   -g, --gas-limit            Gas limit"
  echo "   -f, --fees                 Include london fork fees in network ( default: false )"

  echo "   -m, --peer-port            Peer port ( default: 30303 )"
  echo "   -r, --rpc-port             RPC port ( default: 8545 )"
  echo "   -o, --output               Output file -- If outfile selected, run task as daemon ( default: console )"
  echo
  echo "Example: $0 -d ~/l1-miner-data -x"
}

clear_data() {
  rm -rf $DATA_DIR
  mkdir -p $DATA_DIR
}

# Parse command line arguments
while getopts ":hd:xc:p:g:fG:m:r:o:" opt; do
  case ${opt} in
    d|--data )
      DATA_DIR=$OPTARG
      ;;
    h|--help )
      display_help
      exit 0
      ;;
    x|--clear )
      clear_data
      STATE_RESET=1
      ;;
    c|--chain-id )
      CHAIN_ID=$OPTARG
      ;;
    p|--period )
      PERIOD=$OPTARG
      ;;
    g|--gas-limit )
      GAS_LIMIT=$OPTARG
      ;;
    f|--fees )
      FEES=true
      ;;
    G|--geth )
      GETH_BIN=$OPTARG
      ;;
    m|--peer-port )
      PEER_PORT=$OPTARG
      ;;
    r|--rpc-port )
      HTTP_PORT=$OPTARG
      ;;
    o|--output )
      OUTPUT_FILE=$OPTARG
      ;;
    \? )
      echo "Invalid Option: -$OPTARG" 1>&2
      display_help
      exit 1
      ;;
    : )
      echo "Invalid Option: -$OPTARG requires an argument" 1>&2
      display_help
      exit 1
      ;;
  esac
done

# Check if required arguments are set
if [ -z "$DATA_DIR" ]; then
  echo "Missing required argument: -d" 1>&2
  display_help
  exit 1
fi

# Check if data dir exists
if [ ! -d "$DATA_DIR" ]; then
  echo "Data dir does not exist: $DATA_DIR, setting mode to STATE_RESET=1"
  clear_data
  STATE_RESET=1
fi

# Also check data dir has data
if [ ! -d "$DATA_DIR/geth" ]; then
  echo "Data dir does not contain data: $DATA_DIR, setting mode to STATE_RESET=1"
  clear_data
  STATE_RESET=1
fi


PASSWORD_FILE=$DATA_DIR/password.txt

if [ $STATE_RESET -eq 1 ]; then
  # Check if .eth-accounts exists, if not call 
  if [ -z "$(ls -A ${HOME}/.eth-accounts)" ]; then
    echo "No accounts found, creating new account"
    $WORK_DIR/scripts/generate-account.sh -d ${DATA_DIR} -x
  fi

  cp -r ${HOME}/.eth-accounts/ $DATA_DIR/keystore
  mv $DATA_DIR/keystore/password.txt $PASSWORD_FILE
fi
ACCOUNT1=$(cat $DATA_DIR/keystore/* | jq -r '.address' | head -n 1)
echo "Using account: $ACCOUNT1"

if [ $STATE_RESET -eq 1 ]; then
  # Create Geth Genesis & Init Chain
  GENESIS_FILE=$DATA_DIR/genesis.json
  if [ "$FEES" = true ]; then
    $WORK_DIR/scripts/generate-genesis.sh -a $ACCOUNT1 -b 10000000000000000000 -o $GENESIS_FILE -p $PERIOD -c $CHAIN_ID -g $GAS_LIMIT -C 4200000000000000000000000000000000000000 -P $WORK_DIR/contracts/predeploys/Filestore.sol -f
  else
    $WORK_DIR/scripts/generate-genesis.sh -a $ACCOUNT1 -b 10000000000000000000 -o $GENESIS_FILE -p $PERIOD -c $CHAIN_ID -g $GAS_LIMIT -C 4200000000000000000000000000000000000000 -P $WORK_DIR/contracts/predeploys/Filestore.sol
  fi
  ${GETH_BIN} init --datadir $DATA_DIR $GENESIS_FILE

  # Copy over address & keystore
  rm -rf ${HOME}/.transactor
  mkdir -p ${HOME}/.transactor
  for p in  ${DATA_DIR}/keystore/*; do cp $p ${HOME}/.transactor; break; done
fi

if [ -z $OUTPUT_FILE ]; then
  echo "No output file specified, logging to console"
  ${GETH_BIN} --networkid $CHAIN_ID --datadir $DATA_DIR --http --http.api "eth,net,web3,personal,txpool,debug,admin" --http.port $HTTP_PORT --unlock "0x$ACCOUNT1" --mine --allow-insecure-unlock --password $PASSWORD_FILE --miner.etherbase "0x$ACCOUNT1" --miner.gaslimit $GAS_LIMIT --http.corsdomain "*" --port $PEER_PORT --metrics --metrics.addr 127.0.0.1 --metrics.expensive --metrics.port 6060
else
  echo "Logging to $OUTPUT_FILE"
  ${GETH_BIN} --networkid $CHAIN_ID --datadir $DATA_DIR --http --http.api "eth,net,web3,personal,txpool,debug,admin" --http.port $HTTP_PORT --unlock "0x$ACCOUNT1" --mine --allow-insecure-unlock --password $PASSWORD_FILE --miner.etherbase "0x$ACCOUNT1" --miner.gaslimit $GAS_LIMIT --http.corsdomain "*" --port $PEER_PORT --metrics --metrics.addr 127.0.0.1 --metrics.expensive --metrics.port 6060 > $OUTPUT_FILE 2>&1 &
fi
