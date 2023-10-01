SEQUENCER_ADDRESS ?= $(shell cat ~/fraktal-data/keystore/UTC* | jq -r '.address')

launch-fraktal:
	./scripts/run-fraktal.sh

build-contracts:
	cd contracts && make build-contracts

deploy-contracts:
	cd contracts && SEQUENCER_ADDRESS=${SEQUENCER_ADDRESS} make deploy-contracts

call-main:
	cd contracts && SEQUENCER_ADDRESS=${SEQUENCER_ADDRESS} make call-main

test-contracts:
	cd contracts && make test-contracts

build-solidity:
	cd solidity && ./scripts/build.sh

build-go-ethereum:
	cd go-ethereum && make all

build-submodules: build-go-ethereum build-solidity build-contracts
