// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../openzeppelin/contracts/utils/math/SafeMath.sol";
import "hardhat/console.sol";

library TokenAllocation {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.UintSet;

    uint256 public constant maxAllocationSize = 200;
    struct TokenIdAllocation {
        uint256 share;
        uint256 size;
        uint256 ratePerSecond;
        EnumerableSet.UintSet revokedTokenIds;
    }

    function checkIfRevoked(TokenIdAllocation storage ta, uint256 tokenId)
        public
        view
        returns (bool)
    {
        return ta.revokedTokenIds.contains(tokenId);
    }

    function revokeToken(TokenIdAllocation storage ta, uint256 tokenId)
        internal
        returns (bool)
    {
        ta.revokedTokenIds.add(tokenId);
        return true;
    }

    function getMaxAllocationSize() public pure returns (uint256) {
        return maxAllocationSize;
    }

    function getTokenRate(TokenIdAllocation storage ta, uint256 tokenId)
        internal
        view
        returns (uint256)
    {
        if (checkTokenId(ta, tokenId)) {
            return ta.ratePerSecond;
        }
        return 0;
    }

    function getAlloctionStart(uint256 tokenId)
        internal
        pure
        returns (uint256)
    {
        return tokenId.div(maxAllocationSize).mul(maxAllocationSize);
    }

    function checkTokenId(TokenIdAllocation storage ta, uint256 tokenId)
        internal
        view
        returns (bool)
    {
        uint256 startIndex = getAlloctionStart(tokenId);
        if (
            tokenId >= startIndex &&
            tokenId < startIndex.add(ta.size) &&
            !ta.revokedTokenIds.contains(tokenId)
        ) {
            return true;
        }
        return false;
    }
}
