// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Test {
 //   uint256 public storedValue;

//    function test(uint256 _value) public {
//        assembly {
//            mstore(0x00, _value)
//        }
//    }

    function main() external {
      assembly {
        mstore(0x00, 0x42)
//        sstore(0x01, mload(0x00))
      }
 //       test(0x40);
    }
}
