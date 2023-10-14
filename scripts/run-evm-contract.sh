#!/bin/bash
#
# Compiles a sol contract using the solc submodule, then runs it with the evm binary from go-eth submodule

# Set up the environment
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
WORK_DIR="${SCRIPT_DIR}/.."

# Require passing the CONTRACT_PATH as an argument or env var
if [ -z "$CONTRACT_PATH" ]; then
    if [ -z "$1" ]; then
        echo "Please pass the contract path as an argument or set the CONTRACT_PATH env var"
        exit 1
    else
        CONTRACT_PATH="$1"
    fi
fi

# Default CONTRACT_INPUT to the main() function signature
if [ -z "$CONTRACT_INPUT" ]; then
  CONTRACT_INPUT=$(cast sig 'main()')
fi

# Compile the contract
BUILD_OUTPUT=$(${WORK_DIR}/solidity/build/solc/solc --bin ${CONTRACT_PATH})
CONTRACT_BIN=$(echo "$BUILD_OUTPUT" | tail -n 1)

# Run the sol contract to get the evm bytecode
INIT_OUTPUT=$(${WORK_DIR}/go-ethereum/build/bin/evm --code ${CONTRACT_BIN} run)
BYTECODE=$(echo "$INIT_OUTPUT" | tail -n 1)

# Run the evm bytecode
echo ""
echo "============================="
echo ""
echo "Running contract: ${CONTRACT_PATH}"
echo ""
${WORK_DIR}/go-ethereum/build/bin/evm --code ${BYTECODE} --input ${CONTRACT_INPUT} run
