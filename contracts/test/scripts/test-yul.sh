#!/bin/bash
#
# Run code to test yul contracts
#
# TODO: Contract return values check

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
GO_ETHEREUM_DIR="${SCRIPT_DIR}/../../../go-ethereum/"
SOLIDITY_DIR="${SCRIPT_DIR}/../../../solidity/"

# Build the Yield test contract
YIELD_CONTRACT="${SCRIPT_DIR}/../yul/yield.yul"
YIELD_BYTECODE=$(${SOLIDITY_DIR}/build/solc/solc --bin --strict-assembly ${YIELD_CONTRACT} | tail -n 1)
echo "Yield yul contract built, bytecode: ${YIELD_BYTECODE}"

YIELD_OUT=$(${GO_ETHEREUM_DIR}/build/bin/evm --code ${YIELD_BYTECODE} run 2>&1)
echo "Ran Yield yul contract, output:"
echo "${YIELD_OUT}"

echo ""

# Build the Spawn test contract
SPAWN_CONTRACT="${SCRIPT_DIR}/../yul/spawn.yul"
SPAWN_BYTECODE=$(${SOLIDITY_DIR}/build/solc/solc --bin --strict-assembly ${SPAWN_CONTRACT} | tail -n 1)
echo "Spawn yul contract built, bytecode: ${SPAWN_BYTECODE}"

SPAWN_OUT=$(${GO_ETHEREUM_DIR}/build/bin/evm --code ${SPAWN_BYTECODE} run 2>&1)
echo "Ran Spawn yul contract, output:"
echo "${SPAWN_OUT}"

echo ""

# Strip outputs for comparison
YIELD_OUT=$(echo "${YIELD_OUT}" | sed -E 's/.*opMstore:/opMstore:/' | tr '\n' ' ')
SPAWN_OUT=$(echo "${SPAWN_OUT}" | sed -E 's/.*opMstore:/opMstore:/' | tr '\n' ' ')

EXPECTED_YIELD_OUT="opMstore: mStart=\[128 0 0 0\], val=\[66 0 0 0\] opMstore: mStart=\[160 0 0 0\], val=\[50 0 0 0\]"
EXPECTED_SPAWN_OUT="opMstore: mStart=\[128 0 0 0\], val=\[66 0 0 0\] opMstore: mStart=\[160 0 0 0\], val=\[50 0 0 0\] 0x00000000000000000000000000000000000000000000000000000000000000420000000000000000000000000000000000000000000000000000000000000032"

echo "=========================================================================="
echo "=========================================================================="
echo ""
echo "Tests :"
echo ""
echo "Checking Yield contract bytecode segment '6042608052fc603260a052' : " $(echo "${YIELD_BYTECODE}" | grep -q "6042608052fc603260a052" && echo "PASS" || echo "FAIL")
echo "Checking Yield contract output : " $(echo "${YIELD_OUT}" | grep -qz "${EXPECTED_YIELD_OUT}" && echo "PASS" || echo "FAIL")
echo "Checking Spawn contract bytecode segment '5b601e6032600afb50506020565b005b' : " $(echo "${SPAWN_BYTECODE}" | grep -q "5b601e6032600afb50506020565b005b" && echo "PASS" || echo "FAIL")
echo "Checking Spawn contract output : " $(echo "${SPAWN_OUT}" | grep -qz "${EXPECTED_SPAWN_OUT}" && echo "PASS" || echo "FAIL")
