// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract MyWallet {
    string public name;
    mapping(address => bool) private approved;

    struct OwnableStorage {
        address _owner;
    }

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.Ownable")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant OwnableStorageLocation = 0x9016d09d72d40fdae2fd8ceac6b6234c7706214fd39c1cd1e609a0528c199300;

    modifier auth() {
        OwnableStorage storage $ = _getOwnableStorage();
        require(msg.sender == $._owner, "Not authorized");
        _;
    }

    constructor(string memory _name) {
        name = _name;
        OwnableStorage storage $ = _getOwnableStorage();
        $._owner = msg.sender;
    }

    function _getOwnableStorage() private pure returns (OwnableStorage storage $) {
        assembly {
            $.slot := OwnableStorageLocation
        }
    }

    function transferOwernship(address _addr) public auth {
        require(_addr != address(0), "New owner is the zero address");
        OwnableStorage storage $ = _getOwnableStorage();
        address oldOwner = $._owner;
        require(oldOwner != _addr, "New owner is the same as the old owner");
        $._owner = _addr;
    }
}
