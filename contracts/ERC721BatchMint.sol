// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./openzeppelin/contracts/utils/math/SafeMath.sol";
import "./StreamV3.sol";

// import "hardhat/console.sol";

contract ERC721BatchMint is ERC721Enumerable {
    using SafeMath for uint256;

    constructor(string memory name_, string memory symbol_)
        ERC721(name_, symbol_)
    {}

    /**
     * Mints NFT
     */
    function mintBatchByStreamId(
        address _streamV3,
        uint256 streamId,
        uint256 startIndex,
        address receiver
    ) external {
        (, uint256 alloSize, ) = StreamV3(_streamV3).getAllocationInfo(
            streamId,
            startIndex
        );
        require(alloSize > 0, "alloSize must greater than zero");
        for (uint256 i = startIndex; i < startIndex.add(alloSize); i++) {
            _safeMint(receiver, i);
        }
    }

    function mintBatch(
        uint256 startIndex,
        uint256 mintAmount,
        address receiver
    ) external {
        require(mintAmount > 0, "mint amount must greater than zero");
        for (uint256 i = startIndex; i < startIndex.add(mintAmount); i++) {
            _safeMint(receiver, i);
        }
    }

    function mint(uint256 tokenId, address receiver) external {
        _safeMint(receiver, tokenId);
    }

    function exists(uint256 tokenId) external view returns (bool) {
        return _exists(tokenId);
    }

    function unmintTokenAmount(uint256 startIndex, uint256 size)
        external
        view
        returns (uint256 unmintedAmount)
    {
        for (uint256 i = startIndex; i < startIndex.add(size); i++) {
            if (!_exists(i)) {
                unmintedAmount += 1;
            }
        }
    }
}
