// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';

contract EnumerableNFT is ERC721Enumerable{
    constructor () ERC721("test", "test"){
        _mint(msg.sender, 1);
    }
}

contract BasicNFT is ERC721{
    constructor () ERC721("test", "test"){
        _mint(msg.sender, 1);
    }
}
