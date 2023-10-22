SEQUENCER_ADDRESS ?= $(shell cat ~/fraktal-data/keystore/UTC* | jq -r '.address')

all: build-submodules

generate-account:
	./scripts/generate-account.sh -d ${HOME}/fraktal-data/ -x

launch-fraktal: generate-account
	./scripts/run-fraktal.sh -d ${HOME}/fraktal-data/ -x

launch-filestore:
	#TODO: run filestore in background w/ fraktal node
	go run cmd/filestore/filestore.go serve --dataDir ${HOME}/fraktal-data/

launch-web-server:
	go run cmd/web-server/web-server.go --filestore ${HOME}/fraktal-data/filestore/

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

clean:
	cd contracts && make clean
