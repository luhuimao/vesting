// SPDX-License-Identifier: MIT
pragma solidity >=0.5.17;

/**
 * @title IStream1MultiNFTV2
 * @author Benjamin
 */
interface IStream1MultiNFTV2 {
    /**
     * @notice Emits when a stream is successfully created.
     */
    event CreateStream(
        uint256 indexed streamId,
        address indexed sender
        // uint256 deposit,
        // address tokenAddress,
        // uint256 startTime,
        // uint256 stopTime,
        // address erc721Address
    );

    /**
     * @notice Emits when the recipient of a stream withdraws a portion or all their pro rata share of the stream.
     */
    event WithdrawAllFromStream(
        uint256 indexed streamId,
        address indexed sender,
        uint256 amount
    );

    event UpdateStream(
        uint256 indexed streamId,
        uint256 preMintAmount,
        uint256 share
    );

    /**
     * @notice Emits when the recipient of a stream withdraws a portion or all their pro rata share of the stream.
     */
    event WithdrawFromStreamByTokenId(
        uint256 indexed streamId,
        address indexed sender,
        uint256 indexed tokenId,
        uint256 amount
    );

    function availableBalanceForAllNft(
        uint256 streamId,
        address who,
        uint256[] calldata tokenIds
    ) external returns (uint256 balance);

    function getStreamInfo(uint256 streamId)
        external
        view
        returns (
            address sender,
            uint256 deposit,
            address tokenAddress,
            uint256 startTime,
            uint256 stopTime,
            uint256 remainingBalance
        );

    function createMultiNFTStream(
        uint256[3] calldata _uintArgs, //_uintArgs[0] deposit, _uintArgs[1] startTime, _uintArgs[2] stopTime, _uintArgs[3] tokenIdShare
        address tokenAddress,
        uint256[] calldata _uint256ArgsNFTSupply,
        uint256[] calldata _uint256ArgsNFTShares
    ) external returns (uint256 streamId);

    // function updateStream(
    //     uint256 streamId,
    //     uint256 depositAmount,
    //     uint256[] calldata _uint256ArgsNFTSupply,
    //     uint256[] calldata _uint256ArgsNFTShares
    // ) external returns (bool);

    function withdrawAllFromStream(
        uint256 streamId,
        uint256[] calldata tokenIds
    ) external returns (bool);

    function withdrawFromStreamByTokenId(uint256 streamId, uint256 tokenId)
        external
        returns (bool);
}
