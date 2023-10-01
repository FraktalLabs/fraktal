SOLC_EXECUTABLE=../solidity/build/solc/solc

build-contracts:
	${SOLC_EXECUTABLE} --bin --abi contracts/*.sol -o builds/ --overwrite

deploy-contracts:
	@echo "Deploying contracts.."
	SEQUENCER_ADDRESS=$(SEQUENCER_ADDRESS) npm run deploy-contracts

test-contracts:
	@echo "Testing contracts.."
	./test/scripts/test-asm.sh
	./test/scripts/test-yul.sh
	./test/scripts/test-yield-sol.sh
	./test/scripts/test-spawn-sol.sh
