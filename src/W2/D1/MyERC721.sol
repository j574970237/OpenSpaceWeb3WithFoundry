// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract MyERC721 is ERC721URIStorage {
    using Counters for Counters.Counter;
    uint256 private _counter;
    
    constructor() ERC721(unicode"祭杰的NFT", "JJNFT") {}
    
    function mint(address addr, string memory tokenURI) public returns (uint256) {
        _counter++;
        uint256 newItemId = _counter;
        _mint(addr, newItemId);
        _setTokenURI(newItemId, tokenURI);
        return newItemId;
    }

    function totalSupply() public view returns (uint256) {
        return _counter;
    }
}