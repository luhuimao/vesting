// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../openzeppelin/contracts/utils/math/SafeMath.sol";
import "./TokenAllocLibV3.sol";
import "hardhat/console.sol";

library StreamLibV3 {
    using EnumerableSet for EnumerableSet.UintSet;
    // using EnumerableSet for EnumerableSet.AddressSet;
    // using EnumerableSet for EnumerableSet.Bytes32Set;
    using SafeMath for uint256;
    using TokenAllocation for TokenAllocation.TokenIdAllocation;

    struct VestingV3 {
        uint256 deposit;
        uint256 remainingBalance;
        uint256 startTime;
        uint256 stopTime;
        address sender;
        address tokenAddress;
        address erc721Address;
        bool isEntity;
        uint256 lastRevokeIndex;
        EnumerableSet.UintSet allocations;
        mapping(uint256 => TokenAllocation.TokenIdAllocation) tokenAllocations;
        mapping(uint256 => uint256) NFTTokenIdWithdrawalAmount; // tokenId => withdrawal amount
    }

    function addStream(
        VestingV3 storage stream1,
        uint256[2] memory _uintArgs,
        address[3] memory _addressArgs, // address sender,address tokenAddress, address ERC721
        bool isEntity
    ) internal returns (bool) {
        stream1.deposit = 0;
        stream1.remainingBalance = 0;
        stream1.startTime = _uintArgs[0];
        stream1.stopTime = _uintArgs[1];
        stream1.sender = _addressArgs[0];
        stream1.tokenAddress = _addressArgs[1];
        stream1.erc721Address = _addressArgs[2];
        stream1.isEntity = isEntity;

        return true;
    }

    function depositToken(VestingV3 storage stream1, uint256 depositAmount)
        internal
        returns (bool)
    {
        stream1.deposit += depositAmount;
        stream1.remainingBalance += depositAmount;

        return true;
    }

    function updateStream(
        VestingV3 storage stream1,
        uint256 startIndex,
        uint256 preMintAmount,
        uint256 tokenIdShare,
        uint256 ratePerSecond
    ) internal returns (bool) {
        // console.log("Constract Log => startIndex: ", startIndex);
        // console.log("Constract Log => preMintAmount: ", preMintAmount);
        stream1.allocations.add(startIndex);
        stream1.tokenAllocations[startIndex].share = tokenIdShare;
        stream1.tokenAllocations[startIndex].size = preMintAmount;
        stream1.tokenAllocations[startIndex].ratePerSecond = ratePerSecond;
        // stream1.tokenAllocations[startIndex].isActived = true;

        // TokenAllocation.TokenIdAllocation({
        //     share: tokenIdShare,
        //     size: preMintAmount,
        //     ratePerSecond: ratePerSecond,
        //     isActived: true
        // });
        return true;
    }

    function revokeNFT(VestingV3 storage stream, uint256 revokeAmount)
        internal
        returns (bool)
    {

    }

    // function getAllAllocations(VestingV3 storage stream)
    //     external
    //     view
    //     returns (uint256[] memory)
    // {
    //     return stream.allocations.values();
    // }
}
