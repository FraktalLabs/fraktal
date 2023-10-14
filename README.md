# Fraktal
--------

Fraktal is still in the R & D stages, but the high level goal is to create a set of blockchain protocols to support fractal scaling, ephemeral chains, modern programming interfaces, and private networks.

Focused on staying EVM compatible while still adding features on top to support scaling, gaming use cases, user chains, and more.

---

## Current State

Currently, Fraktal clients exist as a fork of the Ethereum Geth client. This means the network is EVM compatible, and supports the same RPC interfaces as Geth nodes. Fraktal node's EVM is a superset of the EVM containing new opcodes for :

- Coroutines  : `YIELD` & `SPAWN`
- Channels    : `CHANCREATE`, `CHANSEND`, & `CHANRECV`
- Console log : `CLOG`

## How to setup & use :

```
git clone git@github.com:FraktalLabs/fraktal.git
cd fraktal
git submodule update --init --recursive
make build-submodules

# Run PrintNumbers Contract to test Coroutines
./scripts/run-evm-contract.sh contracts/contracts/PrintNumbers.sol
# Expected output : 11, 1, 12, 2, 13, 3, 14, 4, 15, 16, 17, 18

# Run PubSub Contract to test Channels
./scripts/run-evm-contract.sh contracts/contracts/PubSub.sol
```

---

## Coroutines

### In the EVM
Coroutines allow the EVM to support cooperative multitasking. This is done by allowing an existing routine/process to yield execution to another routine/process. Note that there is no parallel processing and through the `YIELD` and `SPAWN` opcodes functionality, coroutine execution is completely determinstic, so there is no issue with block validation.

Coroutines implemented using similar logic to this article https://abhinavsarkar.net/posts/implementing-co-3/. The main coroutine queue exists within a `ScopeContext`, which means that it runs / exists within an executing contract. Yielding a coroutine means to store the Interpreter's `Stack` and program counter into a `Coroutine` object, and add it to the queue. Yielding and reaching the end of execution causes the next Coroutine to pop off the queue and resume execution with its Stack and PC.

Spawn adds a coroutine to the main queue which starts at the given PC ( allowing function calls to be added to the queue )

### In Solidity / Yul
To use coroutines more easily in a smart contract you can use them in solidity like :
```
contract PrintNumbers {
  event Log(uint256);

  function printNums(uint256 _start, uint256 _end) public {
      for (uint256 i = _start; i <= _end; i++) {
        assembly {
          mstore(0x00, i)
        }
        emit Log(i);
        yield();
      }
  }

  function main() external {
    spawn printNums(0x01, 0x04);
    printNums(0x0b, 0x12);
  }
}
```

Or in Yul like :
```
yield()
spawn(func1(0x42))
```

## Channels

### In the EVM
Channels allows for easy communication between Threads of Computation ( or Coroutines ). This is done by giving coroutines the ability to send & receive messages with channels. Channels are a bit more complex than Coroutines, but through the opcodes `CHANCREATE`, `CHANSEND`, and `CHANRECV` coroutines can be managed by these channels and messages can be sent between running routines.

Channels were implemented using similar logic to this article https://abhinavsarkar.net/posts/implementing-co-4/. Channels are stored inside the `ScopeContext` and are indexed by id in the `Channels` array. After creating a channel with `CHANCREATE` & giving it a buffer size, any executing coroutine can send and receive messages to and from the channel with `CHANSEND` and `CHANRECV`.j-

### In Solidity / Yul
To use channels more easily in a smart contract you can use them in solidity like :
```
function func1(channel inbox) external {
  while (true) {
    uint256 val <- inbox;
    emit Log(val);
  }
}

function func2(channel inbox, uint256 count) external {
  for (uint256 i = 1; i < count + 1; i++) {
    i -> inbox;
  }
}

function main() external {
  channel inbox = chancreate(4)
  spawn func1(inbox)
  func2(inbox, 7)
}
```

Or in Yul like :
```
chancreate(4)
chansend(chanId, val)
val = chanrecv(chanId)
```

## Console Log

### In the EVM
Added opcode to support log.Println to the console / node from string in EVM memory. Uses the same syntax / encoding as Solidity with memory strings, and takes a pointer to the string's length in memory of the stack as an argument.

This is done through the `CLOG` opcode and makes testing and development a lot easier and more friendly when using `go-ethereum/build/bin/evm`.

### In Solidity / Yul
To use console logging in solidity :
```
string memory printMsg = string.concat("Hello, ", "World!");
print(printMsg);
```

And in Yul, once the string is setup in memory :
```
clog(stringPtr/LengthPos)
```

---
## Useful Links / References :
- https://hackmd.io/@kalmanlajko/rkgg9GLG5
- https://abhinavsarkar.net/posts/implementing-co-3/


## Future features
- filestore
- oracle(s)
- cross contract channels & coroutines
- Ephemeral & Distributed storage, nodes, and environments
- cross chain interoperability
