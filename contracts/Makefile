SOLC_EXECUTABLE=../solidity/build/solc/solc

build-contracts:
	${SOLC_EXECUTABLE} --bin --abi contracts/*.sol -o builds/ --overwrite

deploy-contracts:
	@echo "Deploying contracts.."
	SEQUENCER_ADDRESS=$(SEQUENCER_ADDRESS) npm run deploy-contracts

FUNC_SIG=$(shell cast sig 'main()')
call-main:
	@echo "Calling main() on contract.."
	SEQUENCER_ADDRESS=$(SEQUENCER_ADDRESS) FUNC_SIG=$(FUNC_SIG) CONTRACT_ADDRESS=$(CONTRACT_ADDRESS) ./scripts/call-contract.sh

test-contracts:
	@echo "Testing contracts.."
	./test/scripts/test-asm.sh
	./test/scripts/test-yul.sh
	./test/scripts/test-yield-sol.sh
	./test/scripts/test-spawn-sol.sh
