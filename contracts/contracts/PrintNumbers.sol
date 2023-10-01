// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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
