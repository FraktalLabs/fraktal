// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PrintNumbers {
  event Log(uint256);

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
      if (_i == 0) {
          return "0";
      }
      uint j = _i;
      uint len;
      while (j != 0) {
          len++;
          j /= 10;
      }
      bytes memory bstr = new bytes(len);
      uint k = len;
      while (_i != 0) {
          k = k-1;
          uint8 temp = (48 + uint8(_i - _i / 10 * 10));
          bytes1 b1 = bytes1(temp);
          bstr[k] = b1;
          _i /= 10;
      }
      return string(bstr);
  }

  function printNums(uint256 _start, uint256 _end) public {
      for (uint256 i = _start; i <= _end; i++) {
        assembly {
          mstore(0x00, i)
        }
        string memory s = uint2str(i);
        print(s);
        emit Log(i);
        yield();
      }
  }

  function main() external {
    spawn printNums(0x01, 0x04);
    printNums(0x0b, 0x12);
  }
}
