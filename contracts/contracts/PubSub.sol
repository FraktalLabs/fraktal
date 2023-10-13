// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PubSubTest {

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

  function worker(uint256 name, channel msgChannel, channel ackChannel) public {
    string memory printmsg = string.concat("worker ", uint2str(name), " starting");
    print(printmsg);
    while (true) {
      uint256 val <- msgChannel;
      printmsg = string.concat("worker ", uint2str(name), " received : ", uint2str(val));
      print(printmsg);
      if (val == 0) { // TODO: null
        printmsg = string.concat("worker ", uint2str(name), " stopping");
        print(printmsg);
        return;
      }
      printmsg = string.concat("worker ", uint2str(name), " sending: ", uint2str(val));
      print(printmsg);
      val -> ackChannel;
      printmsg = string.concat("worker ", uint2str(name), " sent: ", uint2str(val));
      print(printmsg);
    }
  }

  function startServer(channel msgChannel, uint256 count) public {
    string memory printmsg = string.concat("server starting");
    print(printmsg);
    for (uint256 i = 1; i < count + 1; i++) {
      printmsg = string.concat("server sending : ", uint2str(i));
      print(printmsg);
      i -> msgChannel;
      printmsg = string.concat("server sent : ", uint2str(i));
      print(printmsg);
    }
  }

  function startWorkers(uint256 count, channel msgChannel, channel ackChannel) public {
    string memory printmsg = string.concat("workers starting");
    print(printmsg);
    for (uint256 i = 1; i < count + 1; i++) {
      spawn worker(i, msgChannel, ackChannel);
    }
    printmsg = string.concat("workers scheduled to be started");
    print(printmsg);
  }

  function waitForWorkers(uint256 count, channel ackChannel, channel doneChannel) public {
    string memory printmsg = string.concat("server waiting for acks");
    print(printmsg);
    for (uint256 i = 1; i < count + 1; i++) {
      uint256 val <- ackChannel;
      printmsg = string.concat("server received : ", uint2str(val));
      print(printmsg);
    }
    printmsg = string.concat("server received all acks");
    print(printmsg);
    0x00 -> doneChannel;
  }

  function stopWorkers(uint256 count, channel msgChannel, channel doneChannel) public {
    uint256 done <- doneChannel;
    string memory printmsg = string.concat("server received done");
    print(printmsg);
    for (uint256 i = 1; i < count + 1; i++) {
      0x00 -> msgChannel;
    }
    printmsg = string.concat("server sent stop to all workers");
    print(printmsg);
  }

  function main() external {
    uint256 workerCount = 3;
    uint256 messageCount = 7;
    uint8 messageBufferSize = 5;
    uint8 ackBufferSize = 1;
    uint8 doneBufferSize = 3;

    channel msgChannel = chancreate(messageBufferSize);
    channel ackChannel = chancreate(ackBufferSize);
    channel doneChannel = chancreate(doneBufferSize);

    startWorkers(workerCount, msgChannel, ackChannel);
    spawn waitForWorkers(messageCount, ackChannel, doneChannel);
    startServer(msgChannel, messageCount);
    stopWorkers(workerCount, msgChannel, doneChannel);
  }

}
