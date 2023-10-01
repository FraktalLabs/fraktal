#!/bin/bash
#
# Run code to test assembly contracts
#
# TODO: Contract return values check

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
GO_ETHEREUM_DIR="${SCRIPT_DIR}/../../../go-ethereum/"

# Build the Yield test contract
YIELD_CONTRACT="${SCRIPT_DIR}/../asm/yield.txt"
YIELD_BYTECODE=$(${GO_ETHEREUM_DIR}/build/bin/evm compile ${YIELD_CONTRACT})
echo "Yield asm contract built, bytecode: ${YIELD_BYTECODE}"

YIELD_OUT=$(${GO_ETHEREUM_DIR}/build/bin/evm --code ${YIELD_BYTECODE} run 2>&1)
echo "Ran Yield asm contract, output:"
echo "${YIELD_OUT}"

echo ""

# Build the Spawn test contract
SPAWN_CONTRACT="${SCRIPT_DIR}/../asm/spawn.txt"
SPAWN_BYTECODE=$(${GO_ETHEREUM_DIR}/build/bin/evm compile ${SPAWN_CONTRACT})
echo "Spawn asm contract built, bytecode: ${SPAWN_BYTECODE}"

SPAWN_OUT=$(${GO_ETHEREUM_DIR}/build/bin/evm --code ${SPAWN_BYTECODE} run 2>&1)
echo "Ran Spawn asm contract, output:"
echo "${SPAWN_OUT}"

echo ""

# Strip outputs for comparison
YIELD_OUT=$(echo "${YIELD_OUT}" | sed -E 's/.*opMstore:/opMstore:/' | tr '\n' ' ')
SPAWN_OUT=$(echo "${SPAWN_OUT}" | sed -E 's/.*opMstore:/opMstore:/' | tr '\n' ' ')

EXPECTED_YIELD_OUT="opMstore: mStart=\[0 0 0 0\], val=\[32 0 0 0\] opMstore: mStart=\[32 0 0 0\], val=\[13 0 0 0\] opMstore: mStart=\[64 0 0 0\], val=\[0 0 8030600262861193216 5216694956356018263\]"
EXPECTED_SPAWN_OUT="opMstore: mStart=\[0 0 0 0\], val=\[50 0 0 0\] opMstore: mStart=\[0 0 0 0\], val=\[82 0 0 0\] opMstore: mStart=\[0 0 0 0\], val=\[66 0 0 0\]"

echo "=========================================================================="
echo "=========================================================================="
echo ""
echo "Tests :"
echo ""
echo "Checking Yield contract bytecode segment '600d602052fc7f4865' : " $(echo "${YIELD_BYTECODE}" | grep -q "600d602052fc7f4865" && echo "PASS" || echo "FAIL")
echo "Checking Yield contract output : " $(echo "${YIELD_OUT}" | grep -qz "${EXPECTED_YIELD_OUT}" && echo "PASS" || echo "FAIL")
echo "Checking Spawn contract bytecode segment '5b601d60426003fb5050601f565b005b' : " $(echo "${SPAWN_BYTECODE}" | grep -q "5b601d60426003fb5050601f565b005b" && echo "PASS" || echo "FAIL")
echo "Checking Spawn contract output : " $(echo "${SPAWN_OUT}" | grep -qz "${EXPECTED_SPAWN_OUT}" && echo "PASS" || echo "FAIL")
