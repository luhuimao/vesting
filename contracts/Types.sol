// pragma solidity =0.5.17;
pragma solidity ^0.8.0;

/**
 * @title Sablier Types
 * @author Sablier
 */
library Types {
    struct Stream {
        uint256 deposit;
        uint256 ratePerSecond;
        uint256 remainingBalance;
        uint256 startTime;
        uint256 stopTime;
        // address recipient;
        address sender;
        address tokenAddress;
        bool isEntity;
        address erc721Address;
        uint256 tokenId;
    }
}

library VestingTypes {
    struct VestingStream {
        uint256 deposit;
        uint256 ratePerSecond;
        uint256 remainingBalance;
        uint256 startTime;
        uint256 stopTime;
        address sender;
        address tokenAddress;
        bool isEntity;
        address erc721Address;
        uint256 nftTotalSupply;
    }
    struct NFTShares {
        uint256 tokenid;
        uint256 share;
    }
    struct VestingStream2 {
        uint256 deposit;
        uint256 ratePerSecond;
        uint256 remainingBalance;
        uint256 startTime;
        uint256 stopTime;
        address sender;
        address tokenAddress;
        bool isEntity;
        address erc721Address;
        uint256 totalShares;
        // NFTShares[] nftShares;
        //tokenId => share
        mapping(uint256 => uint256) nftShares;
        mapping(uint256 => uint256) claimedAmount;
    }

    function addStream(
        VestingStream storage stream,
        uint256[5] memory arrs,
        // arrs[0] uint256 deposit,
        // arrs[1] uint256 ratePerSecond,
        // arrs[2] uint256 remainingBalance,
        // arrs[3] uint256 startTime,
        // arrs[4] uint256 stopTime,
        address sender,
        address tokenAddress,
        bool isEntity,
        address erc721Address,
        uint256 nftTotalSupply
    ) internal returns (bool) {
        stream.deposit = arrs[0];
        stream.ratePerSecond = arrs[1];
        stream.remainingBalance = arrs[2];
        stream.startTime = arrs[3];
        stream.stopTime = arrs[4];
        stream.sender = sender;
        stream.tokenAddress = tokenAddress;
        stream.isEntity = isEntity;
        stream.erc721Address = erc721Address;
        stream.nftTotalSupply = nftTotalSupply;
        return true;
    }
}
