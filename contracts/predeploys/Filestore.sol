// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//TODO: do a version w/ no remove for different use case & gas savings
//TODO: Convention to store file list at "" key to save gas and make it easier to iterate for user outside the contract
//    That would mean the call order would be :
//      1. approveFile(newFileName, hash)
//      2. approveFile("", hashOfNewFileList) // interchangable with 3
//      3. addFile(newFileName)
//      4. addFile("")
//    Now it is :
//      1. approveFile(newFileName, hash)
//      2. addFile(newFileName)
contract Filestore {
  // TODO: Use openzepplin Context?

  event FileApproved(address indexed account, string file, uint256 hash);

  //TODO: allow others to own files under a user ( like erc 721 )
  // file : filename containing director path ( in Unix format )
  // hash : hash of the file ( sha256 )
  mapping(address => mapping(string => uint256)) private _files; // user => file => hash

  mapping(address => mapping(string => string)) private _fileLinkedList; // user => files

  function addFile(string memory _file) public { // TODO: figure out who can call this when ( in tx thru consensus when the node has the file that matches its hash in storage -- try to get file from network if not? )
    _fileLinkedList[msg.sender][_file] = _fileLinkedList[msg.sender][""];
    _fileLinkedList[msg.sender][""] = _file;
  }

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

  function approveFile(string memory _file, uint256 _hash) public {
    _files[msg.sender][_file] = _hash;
    emit FileApproved(msg.sender, _file, _hash);
  }

  function stringsEquals(string memory s1, string memory s2) private pure returns (bool) {
      bytes memory b1 = bytes(s1);
      bytes memory b2 = bytes(s2);
      uint256 l1 = b1.length;
      if (l1 != b2.length) return false;
      for (uint256 i=0; i<l1; i++) {
          if (b1[i] != b2[i]) return false;
      }
      return true;
  }

  function removeFile(string memory _file) public {
    delete _files[msg.sender][_file];

    string memory parent;
    //Warning: unbounded gas loop
    while(!stringsEquals(_fileLinkedList[msg.sender][parent], _file)) {
      parent = _fileLinkedList[msg.sender][parent];
    }

    _fileLinkedList[msg.sender][parent] = _fileLinkedList[msg.sender][_fileLinkedList[msg.sender][parent]];
    delete _fileLinkedList[msg.sender][_file];
  }

  function getFileList(address account) public view returns (string memory) {
    string memory fileList = "";
    string memory currentFile = _fileLinkedList[account][""];
    //Warning: unbounded gas loop
    while(!stringsEquals(currentFile, "")) {
      fileList = string(abi.encodePacked(fileList, currentFile, ","));
      currentFile = _fileLinkedList[account][currentFile];
    }
    return fileList;
  }

  function getFileCount(address account) public view returns (uint) {
    uint count = 0;
    string memory currentFile = _fileLinkedList[account][""];
    //Warning: unbounded gas loop
    while(!stringsEquals(currentFile, "")) {
      count++;
      currentFile = _fileLinkedList[account][currentFile];
    }
    return count;
  }

  function getFileList() public view returns (string memory) {
    return getFileList(msg.sender);
  }

 // function getFileCount()

  function getFileHash(address account, string memory _file) public view returns (uint256) {
    return _files[account][_file];
  }

  function getFileHash(string memory _file) public view returns (uint256) {
    return _files[msg.sender][_file];
  }
  //TODO: hash from string to uint256
}
