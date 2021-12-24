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
    event WithdrawAllFromStream(
        uint256 indexed streamId,
        address indexed recipient,
        uint256 amount
    );

    /**
     * @notice Emits when the recipient of a stream withdraws a portion or all their pro rata share of the stream.
     */
    event WithdrawFromStreamByTokenId(
        uint256 indexed streamId,
        address indexed recipient,
        uint256 indexed tokenId,
        address erc721Address,
        uint256 amount
    );

    function balanceOf(uint256 streamId, address who)
        external
        view
        returns (uint256 balance);

    function getStreamInfo(uint256 streamId)
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
            address erc721Address,
            uint256 tokenId
        );

    function createStream(
        uint256 deposit,
        address tokenAddress,
        uint256 startTime,
        uint256 stopTime,
        address erc721Address
    ) external returns (uint256 streamId);

    function updateStream(uint256 streamId, address erc721Address)
        external
        returns (bool);

    function withdrawAllFromStream(uint256 streamId) external returns (bool);

    function withdrawFromStreamByTokenId(
        uint256 streamId,
        address erc721Address,
        uint256 tokenId
    ) external returns (bool);
}
