// SPDX-License-Identifier: MIT
pragma solidity >=0.5.17;

/**
 * @title IVesting
 * @author Benjamin
 */
interface IVesting2 {
    /**
     * @notice Emits when a stream2 is successfully created.
     */
    event CreateStream2(
        uint256 indexed streamId,
        address indexed sender,
        uint256 deposit,
        address tokenAddress,
        uint256 startTime,
        uint256 stopTime,
        address erc721Address
    );
    /**
     * @notice Emits when the recipient of a stream2 withdraws a portion or all their pro rata share of the stream.
     */
    event WithdrawFromStream2(
        uint256 indexed stream2Id,
        address indexed recipient,
        uint256 amount
    );

    function balanceOf2(uint256 stream2Id, address who)
        external
        view
        returns (uint256 balance);

    function getStream2(uint256 streamId)
        external
        view
        returns (
            address sender,
            uint256 deposit,
            address token,
            uint256 startTime,
            uint256 stopTime,
            uint256 remainingBalance,
            uint256 ratePerSecond,
            address erc721Address
        );

    function withdrawFromStream2(uint256 stream2Id) external returns (bool);

    function withdrawFromStream2ByTokenId(uint256 stream2Id, uint256 tokenId)
        external
        returns (bool);
}
