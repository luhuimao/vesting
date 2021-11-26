pragma solidity >=0.5.17;

/**
 * @title IVesting
 * @author Benjamin
 */
interface IVesting {
    /**
     * @notice Emits when a stream is successfully created.
     */
    event CreateStream(
        uint256 indexed streamId,
        address indexed sender,
        uint256 deposit,
        address tokenAddress,
        uint256 startTime,
        uint256 stopTime,
        address erc721Address
    );
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
     * @notice Emits when the recipient of a stream withdraws a portion or all their pro rata share of the stream.
     */
    event WithdrawFromStream(
        uint256 indexed streamId,
        address indexed recipient
        // uint256 amount
    );

    /**
     * @notice Emits when the recipient of a stream2 withdraws a portion or all their pro rata share of the stream.
     */
    event WithdrawFromStream2(
        uint256 indexed stream2Id,
        address indexed recipient,
        uint256 amount
    );

    /**
     * @notice Emits when a stream is successfully cancelled and tokens are transferred back on a pro rata basis.
     */
    event CancelStream(
        uint256 indexed streamId,
        address indexed sender,
        address indexed recipient,
        uint256 senderBalance,
        uint256 recipientBalance
    );

    function balanceOf(uint256 streamId, address who)
        external
        view
        returns (uint256 balance);

    function balanceOf2(uint256 stream2Id, address who)
        external
        view
        returns (uint256 balance);

    function getStream(uint256 streamId)
        external
        view
        returns (
            address sender,
            // address recipient,
            uint256 deposit,
            address token,
            uint256 startTime,
            uint256 stopTime,
            uint256 remainingBalance,
            uint256 ratePerSecond,
            address erc721Address,
            uint256 tokenId
        );

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

    function createStream(
        uint256 deposit,
        address tokenAddress,
        uint256 startTime,
        uint256 stopTime,
        address erc721Address,
        uint256 nftTotalSupply
    ) external returns (uint256 streamId);

    function withdrawFromStream(uint256 streamId) external returns (bool);

    function withdrawFromStream2(uint256 stream2Id) external returns (bool);
}
