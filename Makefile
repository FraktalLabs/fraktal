SEQUENCER_ADDRESS ?= $(shell cat ~/fraktal-data/keystore/UTC* | jq -r '.address')

launch-fraktal:
	./scripts/run-fraktal.sh

build-contracts:
	cd contracts && make build-contracts

deploy-contracts:
	cd contracts && SEQUENCER_ADDRESS=${SEQUENCER_ADDRESS} make deploy-contracts

test-contracts:
	cd contracts && make test-contracts
