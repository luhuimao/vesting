// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../ERC721.sol";
import "../openzeppelin/contracts/access/Ownable.sol";

contract TestNFT is ERC721, Ownable {
    using SafeMath for uint256;

    uint256 public MAX_AMOUNT;

    constructor(
        string memory name,
        string memory symbol,
        uint256 maxNftSupply
    ) ERC721(name, symbol) {
        MAX_AMOUNT = maxNftSupply;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _setBaseURI(baseURI);
    }

    function mint(uint256 numberOfTokens) public payable {
        require(
            totalSupply().add(numberOfTokens) <= MAX_AMOUNT,
            "Mint amount would exceed max supply"
        );
        // require(
        //     cyberPrice.mul(numberOfTokens) <= msg.value,
        //     "Ether value sent is not correct"
        // );

        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 mintIndex = totalSupply();
            if (totalSupply() < MAX_AMOUNT) {
                _safeMint(msg.sender, mintIndex);
            }
        }

        // If we haven't set the starting index and this is either 1) the last saleable token or 2) the first token to be sold after
        // the end of pre-sale, set the starting index block
        // if (
        //     startingIndexBlock == 0 &&
        //     (totalSupply() == MAX_CYBERS || block.timestamp >= REVEAL_TIMESTAMP)
        // ) {
        //     startingIndexBlock = block.number;
        // }
    }
}
