// SPDX-License-Identifier: MIT
pragma solidity >=0.5.17;

/**
 * @title IVestingV3
 * @author Benjamin
 */
interface IVestingV3 {
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
     * @notice Emits when the recipient of a stream2 withdraws a portion or all their pro rata share of the stream.
     */
    event WithdrawFromStream(
        uint256 indexed stream2Id,
        address indexed recipient,
        uint256 amount
    );

    event WithdrawAllFromStream(
        uint256 indexed streamId,
        address indexed recipient,
        uint256 amount
    );

    event WithdrawFromStreamByTokenId(
        uint256 indexed streamId,
        address indexed recipient,
        uint256 tokenId,
        uint256 amount
    );

    event SenderWithdraw(uint256 indexed streamId, uint256 amount);

    // function balanceOf(uint256 stream2Id, address who)
    //     external
    //     view
    //     returns (uint256 balance);

    function getStreamInfo(uint256 streamId)
        external
        view
        returns (
            address sender,
            uint256 deposit,
            address token,
            uint256 startTime,
            uint256 stopTime,
            uint256 remainingBalance
        );

    function withdrawAllFromStream(
        uint256 streamId,
        uint256[] calldata tokenIds
    ) external returns (bool);

    function withdrawFromStreamByTokenId(uint256 streamId, uint256 tokenId)
        external
        returns (bool);

    function senderWithdrawFromStream(uint256 streamId) external returns (bool);

    // function withdrawFromStream(uint256 stream2Id) external returns (bool);

    // function withdrawFromStream2ByTokenId(uint256 stream2Id, uint256 tokenId)
    //     external
    //     returns (bool);
}
