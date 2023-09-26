SEQUENCER_ADDRESS ?= $(shell cat ~/fraktal-data/keystore/UTC* | jq -r '.address')

launch-fraktal:
	./scripts/run-fraktal.sh

build-contracts:
	cd contracts && make build-contracts

deploy-contracts:
	cd contracts && SEQUENCER_ADDRESS=${SEQUENCER_ADDRESS} make deploy-contracts

FUNC_SIG ?= $(shell cast sig 'main()')
CONTRACT_ADDRESS ?= $(shell cat contracts/builds/test-address.txt | jq -r '.address')

call-contract:
	FUNC_SIG=${FUNC_SIG} CONTRACT_ADDRESS=${CONTRACT_ADDRESS} SEQUENCER_ADDRESS=${SEQUENCER_ADDRESS} ./scripts/call-contract.sh
