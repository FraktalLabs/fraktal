build:
	# Build intx
	cd intx && cmake -B build -DCMAKE_BUILD_TYPE=Release
	# Build ethash
	cd ethash && mkdir build
	cd ethash/build && cmake ..
	cd ethash/build && cmake --build .
	# Build proc-evm
	cd proc-evm && make all
	# Build fraktal-state-db
	cd fraktal-state-db && make all
	# Build fraktal-vm
	cd fraktal-vm && make all

clean:
	# Clean intx
	cd intx && rm -rf build
	# Clean ethash
	cd ethash && rm -rf build
	# Clean proc-evm
	cd proc-evm && make clean
	# Clean fraktal-state-db
	cd fraktal-state-db && make clean
	# Clean fraktal-vm
	cd fraktal-vm && make clean
