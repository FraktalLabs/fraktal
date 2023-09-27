// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Test {
  event Log(uint256);

  function main() external {
    uint256 value = 0x42;

    assembly {
      mstore(0x00, 0x42)
      yield()
      mstore(0x00, 0x43)
    }

    emit Log(value);
  }
}
