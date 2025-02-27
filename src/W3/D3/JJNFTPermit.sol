// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract JJNFTPermit is ERC721URIStorage {
    uint256 private _counter;
    bytes32 public constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 tokenId,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant DOMAIN_TYPE_HASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    constructor() ERC721(unicode"祭杰的NFTPermit", "JJNFTP") {}
    
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

    // 验证卖家是否准许spender来操作NFT
    function permit(
        address owner,
        address spender,
        uint256 tokenId,
        uint256 value,
        uint256 nonce,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        require(block.timestamp <= deadline, "NFT Permit expired");
        // 构建签名摘要
        bytes32 structHash = keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, tokenId, value, nonce, deadline));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR(), structHash));
        // 验证签名
        address signer = ECDSA.recover(digest, v, r, s);
        require(signer == owner, "Invalid signature");
        // 授权
        _approve(spender, tokenId, owner);
    }

    function DOMAIN_SEPARATOR() public view returns (bytes32) {
        return keccak256(abi.encode(
            DOMAIN_TYPE_HASH,
            keccak256(bytes(name())),
            keccak256(bytes("1")),
            block.chainid,
            address(this)
        ));
    }
}