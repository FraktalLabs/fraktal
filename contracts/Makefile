build-contracts:
	../solidity/build/solc/solc --bin --abi contracts/Test.sol -o builds/ --overwrite

deploy-contracts:
	@echo "Deploying contracts.."
	SEQUENCER_ADDRESS=$(SEQUENCER_ADDRESS) npm run deploy-contracts
