// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./shared-contracts/compound/CarefulMath.sol";
import "./interfaces/IVesting1.sol";
import "./Types.sol";
import "./ERC721.sol";
import "./test/testNFT.sol";
import "hardhat/console.sol";

/**
 * @title Vesting
 * @author Benjamin
 * @notice Money streaming.
 */
contract Vesting1 is IVesting1, ReentrancyGuard, CarefulMath {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using VestingTypes for VestingTypes.VestingStream;

    /*** Storage Properties ***/

    /**
     * @notice Counter for new stream ids.
     */
    uint256 public nextStreamId;
    /**
     * @notice The stream objects identifiable by their unsigned integer ids.
     */
    mapping(uint256 => VestingTypes.VestingStream) private streams;

    // mapping(uint256 => VestingTypes.VestingStream1) private streams1;

    // streamID -> tokenID -> withdrawAmount
    mapping(uint256 => mapping(uint256 => uint256))
        private investorWithdrawalAmount;

    // streamID -> NFTAddress -> tokenID -> withdrawAmount
    mapping(uint256 => mapping(address => mapping(uint256 => uint256)))
        private NFTTokenIdWithdrawalAmount;
    /*** Modifiers ***/

    /**
     * @dev Throws if the caller is not the sender of the recipient of the stream.
     */
    modifier onlySenderOrRecipient(uint256 streamId) {
        require(
            msg.sender == streams[streamId].sender ||
                getNFTBalance(streamId, msg.sender) > 0,
            "caller is not the sender or the recipient of the stream"
        );
        _;
    }

    /**
     * @dev Throws if the caller is not the owner of the spacified tokenId of the stream2.
     */
    modifier onlyNFTOwner(uint256 streamId, uint256 tokenId) {
        address nftAddress = streams[streamId].erc721Address;
        require(
            msg.sender == ERC721(nftAddress).ownerOf(tokenId),
            "caller is not the owner of the tokenId"
        );
        _;
    }

    /**
     * @dev Throws if the caller is not the owner of the spacified tokenId of the stream2.
     */
    modifier onlyNFTOwner1(address nftAddress, uint256 tokenId) {
        require(
            msg.sender == ERC721(nftAddress).ownerOf(tokenId),
            "caller is not the owner of the tokenId"
        );
        _;
    }

    /*
     * @dev Throws if the provided id does not point to a valid stream.
     */
    modifier streamExists(uint256 streamId) {
        require(streams[streamId].isEntity, "stream does not exist");
        _;
    }

    /*** Contract Logic Starts Here */

    constructor() {
        nextStreamId = 100000;
    }

    /*** View Functions ***/
    /*
     * @notice Returns the stream with all its properties.
     * @dev Throws if the id does not point to a valid stream.
     * @param streamId The id of the stream to query.
     * @return The stream object.
     */
    function getStream(uint256 streamId)
        external
        view
        override
        streamExists(streamId)
        returns (
            address sender,
            uint256 deposit,
            address tokenAddress,
            uint256 startTime,
            uint256 stopTime,
            uint256 remainingBalance,
            uint256 ratePerSecond,
            address erc721Address,
            uint256 nftTotalSupply
        )
    {
        sender = streams[streamId].sender;
        deposit = streams[streamId].deposit;
        tokenAddress = streams[streamId].tokenAddress;
        startTime = streams[streamId].startTime;
        stopTime = streams[streamId].stopTime;
        remainingBalance = streams[streamId].remainingBalance;
        ratePerSecond = streams[streamId].ratePerSecond;
        erc721Address = streams[streamId].erc721Address;
        nftTotalSupply = streams[streamId].nftTotalSupply;
    }

    function getNFTBalance(uint256 streamId, address owner)
        internal
        view
        streamExists(streamId)
        returns (uint256)
    {
        address nftAddress = streams[streamId].erc721Address;
        return ERC721(nftAddress).balanceOf(owner);
    }

    /*
     * @notice Returns either the delta in seconds between `block.timestamp` and `startTime` or
     *  between `stopTime` and `startTime, whichever is smaller. If `block.timestamp` is before
     *  `startTime`, it returns 0.
     * @dev Throws if the id does not point to a valid stream.
     * @param streamId The id of the stream for which to query the delta.
     * @return The time delta in seconds.
     */
    function deltaOf(uint256 streamId)
        public
        view
        streamExists(streamId)
        returns (uint256 delta)
    {
        VestingTypes.VestingStream memory stream = streams[streamId];
        if (block.timestamp <= stream.startTime) return 0;
        if (block.timestamp < stream.stopTime)
            return block.timestamp - stream.startTime;
        return stream.stopTime - stream.startTime;
    }

    struct BalanceOfLocalVars {
        MathError mathErr;
        uint256 recipientBalance;
        uint256 withdrawalAmount;
        uint256 senderBalance;
    }

    /*
     * @notice Returns the available funds for the given stream id and address.
     * @dev Throws if the id does not point to a valid stream.
     * @param streamId The id of the stream for which to query the balance.
     * @param who The address for which to query the balance.
     * @return The total funds allocated to `who` as uint256.
     */
    function balanceOf(uint256 streamId, address who)
        public
        view
        override
        streamExists(streamId)
        returns (uint256 balance)
    {
        VestingTypes.VestingStream memory stream = streams[streamId];

        uint256 totalBalance = 0;

        uint256 len = getNFTBalance(streamId, who);
        if (len > 0) {
            for (uint256 j = 0; j < len; j++) {
                //for loop
                uint256 tokenId = ERC721(stream.erc721Address)
                    .tokenOfOwnerByIndex(who, j);
                uint256 singgleBalance = availableBalanceForTokenId(
                    streamId,
                    tokenId
                );
                totalBalance += singgleBalance;
            }
        }

        if (getNFTBalance(streamId, who) > 0) return totalBalance;
        return 0;
    }

    function availableBalanceForTokenId(uint256 streamId, uint256 tokenId)
        public
        view
        streamExists(streamId)
        returns (uint256 balance)
    {
        VestingTypes.VestingStream memory stream = streams[streamId];
        BalanceOfLocalVars memory vars;

        uint256 delta = deltaOf(streamId);
        // console.log("Vesing1 Log => delta: ", delta);
        uint256 totalBalance;
        (vars.mathErr, totalBalance) = mulUInt(delta, stream.ratePerSecond);

        require(
            vars.mathErr == MathError.NO_ERROR,
            "recipient balance calculation error"
        );
        uint256 availableBalance;
        (vars.mathErr, availableBalance) = subUInt(
            totalBalance,
            investorWithdrawalAmount[streamId][tokenId]
        );
        return availableBalance;
    }

    function remainingBalanceByTokenId(uint256 streamId, uint256 tokenId)
        public
        view
        returns (uint256)
    {
        VestingTypes.VestingStream memory stream = streams[streamId];
        uint256 steramDuration = stream.stopTime - stream.startTime;

        uint256 totalBalance = steramDuration.mul(stream.ratePerSecond);
        uint256 tokenidBalance = totalBalance.sub(
            investorWithdrawalAmount[streamId][tokenId]
        );

        return tokenidBalance;
    }

    function balanceOfSender(uint256 streamId)
        public
        view
        streamExists(streamId)
        returns (uint256 balance)
    {
        VestingTypes.VestingStream memory stream = streams[streamId];
        BalanceOfLocalVars memory vars;
        address nftAddress = streams[streamId].erc721Address;
        uint256 maxNFTSupply = TestNFT(nftAddress).MAX_AMOUNT();
        uint256 totalNFTSupply = ERC721(nftAddress).totalSupply();
        uint256 remainingNFT = 0;
        uint256 balancePerNFT = 0;
        (vars.mathErr, balancePerNFT) = divUInt(stream.deposit, maxNFTSupply);
        assert(vars.mathErr == MathError.NO_ERROR);
        (vars.mathErr, remainingNFT) = subUInt(maxNFTSupply, totalNFTSupply);
        assert(vars.mathErr == MathError.NO_ERROR);
        (vars.mathErr, vars.senderBalance) = mulUInt(
            remainingNFT,
            balancePerNFT
        );
        /* `recipientBalance` cannot and should not be bigger than `remainingBalance`. */
        assert(vars.mathErr == MathError.NO_ERROR);
        // return vars.senderBalance;
        return streams[streamId].remainingBalance;
    }

    /*** Public Effects & Interactions Functions ***/

    struct CreateStreamLocalVars {
        MathError mathErr;
        uint256 duration;
        uint256 ratePerSecond;
    }

    /*
     * @notice Creates a new stream funded by `msg.sender` and paid towards `recipient`.
     * @dev Throws if the recipient is the zero address, the contract itself or the caller.
     *  Throws if the deposit is 0.
     *  Throws if the start time is before `block.timestamp`.
     *  Throws if the stop time is before the start time.
     *  Throws if the duration calculation has a math error.
     *  Throws if the deposit is smaller than the duration.
     *  Throws if the deposit is not a multiple of the duration.
     *  Throws if the rate calculation has a math error.
     *  Throws if the next stream id calculation has a math error.
     *  Throws if the contract is not allowed to transfer enough tokens.
     *  Throws if there is a token transfer failure.
     * @param nftAddress The address towards which the money is streamed.
     * @param nftTotalSupply The address towards which the money is streamed.
     * @param deposit The amount of money to be streamed.
     * @param tokenAddress The ERC20 token to use as streaming currency.
     * @param startTime The unix timestamp for when the stream starts.
     * @param stopTime The unix timestamp for when the stream stops.
     * @return The uint256 id of the newly created stream.
     */
    function createStream(
        uint256 deposit,
        address tokenAddress,
        uint256 startTime,
        uint256 stopTime,
        address erc721Address
    )
        public
        override
        returns (
            // uint256 nftTotalSupply
            uint256
        )
    {
        require(erc721Address != address(0x00), "nftAddress is zero address");
        require(deposit > 0, "deposit is zero");
        require(
            startTime >= block.timestamp,
            "start time before block.timestamp"
        );
        require(stopTime > startTime, "stop time before the start time");

        CreateStreamLocalVars memory vars;
        (vars.mathErr, vars.duration) = subUInt(stopTime, startTime);
        /* `subUInt` can only return MathError.INTEGER_UNDERFLOW but we know `stopTime` is higher than `startTime`. */
        assert(vars.mathErr == MathError.NO_ERROR);

        uint256 nftTotalSupply = TestNFT(erc721Address).MAX_AMOUNT();
        require(nftTotalSupply >= 0, "ERROR: nftTotalSupply Is Zero");

        (MathError err, uint256 totalDuration) = mulUInt(
            vars.duration,
            nftTotalSupply
        );
        assert(err == MathError.NO_ERROR);

        /* Without this, the rate per second would be zero. */
        require(deposit >= totalDuration, "deposit smaller than time delta");

        /* This condition avoids dealing with remainders */
        // require(
        //     deposit % totalDuration == 0,
        //     "deposit not multiple of time delta"
        // );

        (vars.mathErr, vars.ratePerSecond) = divUInt(deposit, totalDuration);

        /* `divUInt` can only return MathError.DIVISION_BY_ZERO but we know `duration` is not zero. */
        assert(vars.mathErr == MathError.NO_ERROR);

        /* Create and store the stream object. */
        uint256 streamId = nextStreamId;
        // streams[streamId] = VestingTypes.VestingStream({
        //     remainingBalance: deposit,
        //     deposit: deposit,
        //     isEntity: true,
        //     ratePerSecond: vars.ratePerSecond,
        //     sender: msg.sender,
        //     startTime: startTime,
        //     stopTime: stopTime,
        //     tokenAddress: tokenAddress,
        //     erc721Address: erc721Address,
        //     nftTotalSupply: nftTotalSupply
        // });
        uint256[5] memory arrs;
        arrs[0] = deposit;
        arrs[1] = vars.ratePerSecond;
        arrs[2] = deposit;
        arrs[3] = startTime;
        arrs[4] = stopTime;

        streams[streamId].addStream(
            // deposit,
            // vars.ratePerSecond,
            // deposit,
            // startTime,
            // stopTime,
            arrs,
            msg.sender,
            tokenAddress,
            true,
            erc721Address,
            nftTotalSupply
        );
        /* Increment the next stream id. */
        (vars.mathErr, nextStreamId) = addUInt(nextStreamId, uint256(1));
        require(
            vars.mathErr == MathError.NO_ERROR,
            "next stream id calculation error"
        );

        IERC20(tokenAddress).safeTransferFrom(
            msg.sender,
            address(this),
            deposit
        );
        emit CreateStream(
            streamId,
            msg.sender,
            deposit,
            tokenAddress,
            startTime,
            stopTime,
            erc721Address
        );
        return streamId;
    }

    /**
     * @notice Withdraws from the contract to the recipient's account.
     * @dev Throws if the id does not point to a valid stream.
     *  Throws if the caller is not the sender or the recipient of the stream.
     *  Throws if the amount exceeds the available balance.
     *  Throws if there is a token transfer failure.
     * @param streamId The id of the stream to withdraw tokens from.
     */
    function withdrawFromStream(uint256 streamId)
        external
        override
        nonReentrant
        streamExists(streamId)
        onlySenderOrRecipient(streamId)
        returns (bool)
    {
        VestingTypes.VestingStream memory stream = streams[streamId];

        require(
            block.timestamp < stream.stopTime,
            "Withdraw Error: streaming is ends"
        );

        uint256 balance = balanceOf(streamId, msg.sender);
        require(balance > 0, "withdrawable balance is zero");

        MathError mathErr;

        (mathErr, streams[streamId].remainingBalance) = subUInt(
            stream.remainingBalance,
            balance
        );

        uint256 realAvailableBalance;
        for (uint256 i = 0; i < getNFTBalance(streamId, msg.sender); i++) {
            uint256 tokenId = ERC721(stream.erc721Address).tokenOfOwnerByIndex(
                msg.sender,
                i
            );
            uint256 withdrawAmountPerNFT;
            withdrawAmountPerNFT = availableBalanceForTokenId(
                streamId,
                tokenId
            );
            investorWithdrawalAmount[streamId][tokenId] += withdrawAmountPerNFT;

            realAvailableBalance += withdrawAmountPerNFT;
        }
        require(realAvailableBalance == balance, "Withdraw ERROR");
        /**
         * `subUInt` can only return MathError.INTEGER_UNDERFLOW but we know that `remainingBalance` is at least
         * as big as `amount`.
         */
        assert(mathErr == MathError.NO_ERROR);

        // if (streams[streamId].remainingBalance == 0) delete streams[streamId];

        uint256 vaultRemainingBalance = IERC20(stream.tokenAddress).balanceOf(
            address(this)
        );
        if (balance > vaultRemainingBalance) {
            IERC20(stream.tokenAddress).safeTransfer(
                msg.sender,
                vaultRemainingBalance
            );
            emit WithdrawFromStream(
                streamId,
                msg.sender,
                vaultRemainingBalance
            );
        } else {
            IERC20(stream.tokenAddress).safeTransfer(msg.sender, balance);
            emit WithdrawFromStream(streamId, msg.sender, balance);
        }

        return true;
    }

    /**
     * @notice Withdraws from the contract to the recipient's account.
     * @dev Throws if the id does not point to a valid stream.
     *  Throws if the caller is not the sender or the recipient of the stream.
     *  Throws if the amount exceeds the available balance.
     *  Throws if there is a token transfer failure.
     * @param streamId The id of the stream to withdraw tokens from.
     */
    function withdrawFromStreamByTokenId(uint256 streamId, uint256 tokenId)
        external
        nonReentrant
        streamExists(streamId)
        onlyNFTOwner(streamId, tokenId)
        returns (bool)
    {
        VestingTypes.VestingStream memory stream = streams[streamId];

        require(
            block.timestamp < stream.stopTime,
            "Withdraw Error: streaming is ends"
        );

        uint256 balance = availableBalanceForTokenId(streamId, tokenId);
        require(balance > 0, "withdrawable balance is zero");

        MathError mathErr;

        (mathErr, streams[streamId].remainingBalance) = subUInt(
            stream.remainingBalance,
            balance
        );

        investorWithdrawalAmount[streamId][tokenId] += balance;
        /**
         * `subUInt` can only return MathError.INTEGER_UNDERFLOW but we know that `remainingBalance` is at least
         * as big as `amount`.
         */
        assert(mathErr == MathError.NO_ERROR);

        // if (streams[streamId].remainingBalance == 0) delete streams[streamId];

        uint256 vaultRemainingBalance = IERC20(stream.tokenAddress).balanceOf(
            address(this)
        );
        if (balance > vaultRemainingBalance) {
            IERC20(stream.tokenAddress).safeTransfer(
                msg.sender,
                vaultRemainingBalance
            );
            emit WithdrawFromStreamByTokenId(
                streamId,
                msg.sender,
                tokenId,
                vaultRemainingBalance
            );
        } else {
            IERC20(stream.tokenAddress).safeTransfer(msg.sender, balance);
            emit WithdrawFromStreamByTokenId(
                streamId,
                msg.sender,
                tokenId,
                balance
            );
        }

        return true;
    }

    function senderWithdrawFromStream(uint256 streamId)
        external
        nonReentrant
        streamExists(streamId)
        onlySenderOrRecipient(streamId)
        returns (bool)
    {
        VestingTypes.VestingStream memory stream = streams[streamId];
        require(msg.sender == stream.sender, "Vesting: Permission Deny");
        require(
            block.timestamp >= stream.stopTime,
            "Sender withdraw Error: block timestamp < stoptime"
        );
        uint256 balance = balanceOfSender(streamId);
        require(balance > 0, "Sender Withdrawable Balance Is Zero");

        MathError mathErr;

        (mathErr, streams[streamId].remainingBalance) = subUInt(
            stream.remainingBalance,
            balance
        );

        /**
         * `subUInt` can only return MathError.INTEGER_UNDERFLOW but we know that `remainingBalance` is at least
         * as big as `amount`.
         */
        assert(mathErr == MathError.NO_ERROR);

        // if (streams[streamId].remainingBalance == 0) delete streams[streamId];

        IERC20(stream.tokenAddress).safeTransfer(msg.sender, balance);
        return true;
    }
}
