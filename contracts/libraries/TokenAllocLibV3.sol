// SPDX-License-Identifier: MIT
// pragma solidity =0.5.17;
pragma solidity ^0.8.0;
// import "../openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../openzeppelin/contracts/utils/math/SafeMath.sol";
import "hardhat/console.sol";

library TokenAllocation {
    using SafeMath for uint256;

    uint256 public constant maxAllocationSize = 200;
    struct TokenIdAllocation {
        uint256 share;
        uint256 size;
        uint256 ratePerSecond;
        bool isActived;
    }

    function getMaxAllocationSize() public pure returns (uint256) {
        return maxAllocationSize;
    }

    function revokeAllocation(TokenIdAllocation storage ta)
        internal
        returns (bool)
    {
        ta.isActived = false;
        return true;
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
            ta.isActived == true
        ) {
            return true;
        }
        return false;
    }

    function checkIfActive(TokenIdAllocation storage ta)
        internal
        view
        returns (bool)
    {
        return ta.isActived;
    }
}
