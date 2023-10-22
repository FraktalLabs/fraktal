SOLC_EXECUTABLE=../solidity/build/solc/solc

go-gen:
	./scripts/go-gen.sh

build-contracts:
	${SOLC_EXECUTABLE} --bin --abi contracts/*.sol -o builds/ --overwrite
	${SOLC_EXECUTABLE} --bin --abi predeploys/*.sol -o builds/predeploys/ --overwrite
	./scripts/go-gen.sh

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

clean:
	rm -rf builds/
	rm -rf go/
