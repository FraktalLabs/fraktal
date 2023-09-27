// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Test2 {
  event Log(uint256);

  function test(uint256 _value) public {
      assembly {
          mstore(0x00, _value)
      }

      emit Log(_value);
  }

  function main() external {
    uint256 value = 0x42;

    assembly {
      mstore(0x00, 0x42)
    }

    yield();

    assembly {
      mstore(0x00, 0x43)
    }

    test(0x32);

    emit Log(value);
  }
}
