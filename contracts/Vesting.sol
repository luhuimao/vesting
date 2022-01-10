// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./shared-contracts/compound/CarefulMath.sol";
import "./interfaces/IVesting.sol";
import "./Types.sol";
import "./ERC721.sol";
import "./test/testNFT.sol";
import "hardhat/console.sol";

/**
 * @title Vesting
 * @author Benjamin
 * @notice Money streaming.
 */
contract Vesting is IVesting, ReentrancyGuard, CarefulMath {
    using SafeERC20 for IERC20;
    using VestingTypes for VestingTypes.VestingStream;
    /*** Storage Properties ***/

    /**
     * @notice Counter for new stream ids.
     */
    uint256 public nextStreamId;

    /**
     * @notice Counter for new stream2 ids.
     */
    uint256 public nextStream2Id;
    /**
     * @notice The stream objects identifiable by their unsigned integer ids.
     */
    mapping(uint256 => VestingTypes.VestingStream) private streams;
    /**
     * @notice The stream2 objects identifiable by their unsigned integer ids.
     */
    mapping(uint256 => VestingTypes.VestingStream2) private stream2s;
    // streamID -> tokenID -> withdrawAmount
    mapping(uint256 => mapping(uint256 => uint256))
        private investorWithdrawalAmount;

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
     * @dev Throws if the caller is not the sender of the recipient of the stream2.
     */
    modifier onlySenderOrRecipient2(uint256 stream2Id) {
        require(
            msg.sender == stream2s[stream2Id].sender ||
                getNFTBalance2(stream2Id, msg.sender) > 0,
            "caller is not the sender or the recipient of the stream"
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

    /*
     * @dev Throws if the provided id does not point to a valid stream2.
     */
    modifier stream2Exists(uint256 stream2Id) {
        require(stream2s[stream2Id].isEntity, "stream does not exist");
        _;
    }

    /*** Contract Logic Starts Here */

    constructor() {
        nextStreamId = 100000;
        nextStream2Id = 200000;
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

    /*** View Functions ***/
    /*
     * @notice Returns the stream with all its properties.
     * @dev Throws if the id does not point to a valid stream.
     * @param stream2Id The id of the stream2 to query.
     * @return The stream2 object.
     */
    function getStream2(uint256 stream2Id)
        external
        view
        override
        stream2Exists(stream2Id)
        returns (
            address sender,
            uint256 deposit,
            address tokenAddress,
            uint256 startTime,
            uint256 stopTime,
            uint256 remainingBalance,
            uint256 ratePerSecond,
            address erc721Address
        )
    {
        sender = stream2s[stream2Id].sender;
        deposit = stream2s[stream2Id].deposit;
        tokenAddress = stream2s[stream2Id].tokenAddress;
        startTime = stream2s[stream2Id].startTime;
        stopTime = stream2s[stream2Id].stopTime;
        remainingBalance = stream2s[stream2Id].remainingBalance;
        ratePerSecond = stream2s[stream2Id].ratePerSecond;
        erc721Address = stream2s[stream2Id].erc721Address;
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

    function getNFTBalance2(uint256 stream2Id, address owner)
        internal
        view
        stream2Exists(stream2Id)
        returns (uint256)
    {
        address nftAddress = stream2s[stream2Id].erc721Address;
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

    /*
     * @notice Returns either the delta in seconds between `block.timestamp` and `startTime` or
     *  between `stopTime` and `startTime, whichever is smaller. If `block.timestamp` is before
     *  `startTime`, it returns 0.
     * @dev Throws if the id does not point to a valid stream2.
     * @param stream2Id The id of the stream2 for which to query the delta.
     * @return The time delta in seconds.
     */
    function deltaOf2(uint256 stream2Id)
        public
        view
        stream2Exists(stream2Id)
        returns (uint256 delta)
    {
        VestingTypes.VestingStream2 storage stream2 = stream2s[stream2Id];
        if (block.timestamp <= stream2.startTime) return 0;
        if (block.timestamp < stream2.stopTime)
            return block.timestamp - stream2.startTime;
        return stream2.stopTime - stream2.startTime;
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
        BalanceOfLocalVars memory vars;

        uint256 delta = deltaOf(streamId);
        //each nft's withdrawable balance in realtime
        (vars.mathErr, vars.recipientBalance) = mulUInt(
            delta,
            stream.ratePerSecond
        );
        require(
            vars.mathErr == MathError.NO_ERROR,
            "recipient balance calculation error"
        );

        uint256 totalBalance = 0;

        uint256 len = getNFTBalance(streamId, who);
        if (len > 0) {
            for (uint256 j = 0; j < len; j++) {
                //for loop
                uint256 tokenId = ERC721(stream.erc721Address)
                    .tokenOfOwnerByIndex(who, j);
                (vars.mathErr, vars.recipientBalance) = subUInt(
                    vars.recipientBalance,
                    investorWithdrawalAmount[streamId][tokenId]
                );
                totalBalance += vars.recipientBalance;
            }
        }

        // console.log("totalBalance:", totalBalance);
        if (getNFTBalance(streamId, who) > 0) return totalBalance;
        return 0;
    }

    /*
     * @notice Returns the available funds for the given stream2 id and address.
     * @dev Throws if the id does not point to a valid stream2.
     * @param stream2Id The id of the stream for which to query the balance.
     * @param who The address for which to query the balance.
     * @return The total funds allocated to `who` as uint256.
     */
    function balanceOf2(uint256 stream2Id, address who)
        public
        view
        override
        stream2Exists(stream2Id)
        returns (uint256 balance)
    {
        VestingTypes.VestingStream2 storage stream2 = stream2s[stream2Id];
        BalanceOfLocalVars memory vars;

        uint256 delta = deltaOf2(stream2Id);
        (vars.mathErr, vars.recipientBalance) = mulUInt(
            delta,
            stream2.ratePerSecond
        );
        require(
            vars.mathErr == MathError.NO_ERROR,
            "recipient balance calculation error"
        );
        uint256 totalBalance = 0;

        address nftAddress = stream2.erc721Address;
        uint256 nftBalance = ERC721(nftAddress).balanceOf(who);
        if (nftBalance > 0) {
            for (uint256 j = 0; j < nftBalance; j++) {
                //for loop
                uint256 tokenId = ERC721(stream2.erc721Address)
                    .tokenOfOwnerByIndex(who, j);
                uint256 share = stream2.nftShares[tokenId];
                (vars.mathErr, vars.recipientBalance) = mulUInt(
                    vars.recipientBalance,
                    share
                );
                (vars.mathErr, vars.recipientBalance) = divUInt(
                    vars.recipientBalance,
                    1e12
                );
                // (vars.mathErr, vars.recipientBalance) = subUInt(
                //     vars.recipientBalance,
                //     investorWithdrawalAmount[stream2Id][tokenId]
                // );
                (vars.mathErr, vars.recipientBalance) = subUInt(
                    vars.recipientBalance,
                    stream2.claimedAmount[tokenId]
                );
                totalBalance += vars.recipientBalance;
            }
            return totalBalance;
        }
        return 0;
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

    function balanceOfSender2(uint256 stream2Id)
        public
        view
        stream2Exists(stream2Id)
        returns (uint256 balance)
    {
        VestingTypes.VestingStream2 storage stream2 = stream2s[stream2Id];
        // BalanceOfLocalVars memory vars;
        // address nftAddress = stream2.erc721Address;
        // uint256 maxNFTSupply = TestNFT(nftAddress).MAX_AMOUNT();
        // uint256 totalNFTSupply = ERC721(nftAddress).totalSupply();
        // uint256 remainingNFT = 0;
        // uint256 balancePerNFT = 0;
        // (vars.mathErr, balancePerNFT) = divUInt(stream.deposit, maxNFTSupply);
        // assert(vars.mathErr == MathError.NO_ERROR);
        // (vars.mathErr, remainingNFT) = subUInt(maxNFTSupply, totalNFTSupply);
        // assert(vars.mathErr == MathError.NO_ERROR);
        // (vars.mathErr, vars.senderBalance) = mulUInt(
        //     remainingNFT,
        //     balancePerNFT
        // );
        /* `recipientBalance` cannot and should not be bigger than `remainingBalance`. */
        // assert(vars.mathErr == MathError.NO_ERROR);
        // return vars.senderBalance;
        return stream2.remainingBalance;
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
        address erc721Address,
        uint256 nftTotalSupply
    ) public override returns (uint256) {
        require(erc721Address != address(0x00), "nftAddress is zero address");
        // require(recipient != address(this), "stream to the contract itself");
        // require(recipient != msg.sender, "stream to the caller");
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

        (MathError err, uint256 totalDuration) = mulUInt(
            vars.duration,
            nftTotalSupply
        );
        assert(err == MathError.NO_ERROR);

        /* Without this, the rate per second would be zero. */
        require(deposit >= totalDuration, "deposit smaller than time delta");

        /* This condition avoids dealing with remainders */
        require(
            deposit % totalDuration == 0,
            "deposit not multiple of time delta"
        );

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

    function createStream2(
        uint256 deposit,
        address tokenAddress,
        uint256 startTime,
        uint256 stopTime,
        address erc721Address,
        VestingTypes.NFTShares[] memory nftShares
    ) public returns (uint256) {
        require(erc721Address != address(0x00), "nftAddress is zero address");
        require(deposit > 0, "deposit is zero");
        require(nftShares.length > 0, "nftShares length is zero");
        require(
            startTime >= block.timestamp,
            "start time before block.timestamp"
        );
        require(stopTime > startTime, "stop time before the start time");

        CreateStreamLocalVars memory vars;

        (vars.mathErr, vars.duration) = subUInt(stopTime, startTime);
        /* `subUInt` can only return MathError.INTEGER_UNDERFLOW but we know `stopTime` is higher than `startTime`. */
        assert(vars.mathErr == MathError.NO_ERROR);

        /* Without this, the rate per second would be zero. */
        require(deposit >= vars.duration, "deposit smaller than time delta");

        /* This condition avoids dealing with remainders */
        require(
            deposit % vars.duration == 0,
            "deposit not multiple of time delta"
        );

        (vars.mathErr, vars.ratePerSecond) = divUInt(deposit, vars.duration);
        /* `divUInt` can only return MathError.DIVISION_BY_ZERO but we know `duration` is not zero. */
        assert(vars.mathErr == MathError.NO_ERROR);

        /* Create and store the stream2 object. */
        uint256 stream2Id = nextStream2Id;
        uint256 totalShares = 0;
        for (uint256 i = 0; i < nftShares.length; i++) {
            (vars.mathErr, totalShares) = addUInt(
                totalShares,
                nftShares[i].share
            );
            assert(vars.mathErr == MathError.NO_ERROR);
        }
        for (uint256 i = 0; i < nftShares.length; i++) {
            // stream2s[stream2Id].nftShares.push(
            //     VestingTypes.NFTShares(nftShares[i].tokenid, nftShares[i].share)
            // );
            uint256 perShare;
            (vars.mathErr, perShare) = mulUInt(nftShares[i].share, 1e12);
            (vars.mathErr, perShare) = divUInt(perShare, totalShares);
            stream2s[stream2Id].nftShares[nftShares[i].tokenid] = perShare;
        }

        stream2s[stream2Id].remainingBalance = deposit;
        stream2s[stream2Id].deposit = deposit;
        stream2s[stream2Id].isEntity = true;
        stream2s[stream2Id].ratePerSecond = vars.ratePerSecond;
        stream2s[stream2Id].sender = msg.sender;
        stream2s[stream2Id].startTime = startTime;
        stream2s[stream2Id].stopTime = stopTime;
        stream2s[stream2Id].tokenAddress = tokenAddress;
        stream2s[stream2Id].erc721Address = erc721Address;

        /* Increment the next stream id. */
        (vars.mathErr, nextStream2Id) = addUInt(nextStream2Id, uint256(1));
        require(
            vars.mathErr == MathError.NO_ERROR,
            "next stream id calculation error"
        );

        IERC20(tokenAddress).safeTransferFrom(
            msg.sender,
            address(this),
            deposit
        );
        emit CreateStream2(
            stream2Id,
            msg.sender,
            deposit,
            tokenAddress,
            startTime,
            stopTime,
            erc721Address
        );
        return stream2Id;
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

        uint256 withdrawAmountPerNFT = 0;
        (mathErr, withdrawAmountPerNFT) = divUInt(
            balance,
            getNFTBalance(streamId, msg.sender)
        );

        for (uint256 i = 0; i < getNFTBalance(streamId, msg.sender); i++) {
            uint256 tokenId = ERC721(stream.erc721Address).tokenOfOwnerByIndex(
                msg.sender,
                i
            );
            investorWithdrawalAmount[streamId][tokenId] += withdrawAmountPerNFT;
        }
        /**
         * `subUInt` can only return MathError.INTEGER_UNDERFLOW but we know that `remainingBalance` is at least
         * as big as `amount`.
         */
        assert(mathErr == MathError.NO_ERROR);

        if (streams[streamId].remainingBalance == 0) delete streams[streamId];

        IERC20(stream.tokenAddress).safeTransfer(msg.sender, balance);
        emit WithdrawFromStream(streamId, msg.sender);
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

        if (streams[streamId].remainingBalance == 0) delete streams[streamId];

        IERC20(stream.tokenAddress).safeTransfer(msg.sender, balance);
        return true;
    }

    /**
     * @notice Withdraws from the contract to the recipient's account.
     * @dev Throws if the id does not point to a valid stream2.
     *  Throws if the caller is not the sender or the recipient of the stream2.
     *  Throws if the amount exceeds the available balance.
     *  Throws if there is a token transfer failure.
     * @param stream2Id The id of the stream2 to withdraw tokens from.
     */
    function withdrawFromStream2(uint256 stream2Id)
        external
        override
        nonReentrant
        stream2Exists(stream2Id)
        onlySenderOrRecipient2(stream2Id)
        returns (bool)
    {
        VestingTypes.VestingStream2 storage stream2 = stream2s[stream2Id];

        require(
            block.timestamp < stream2.stopTime,
            "Withdraw Error: streaming is ends"
        );

        uint256 balance = balanceOf2(stream2Id, msg.sender);
        require(balance > 0, "withdrawable balance is zero");

        MathError mathErr;

        (mathErr, stream2s[stream2Id].remainingBalance) = subUInt(
            stream2.remainingBalance,
            balance
        );

        for (uint256 i = 0; i < getNFTBalance2(stream2Id, msg.sender); i++) {
            uint256 tokenId = ERC721(stream2.erc721Address).tokenOfOwnerByIndex(
                msg.sender,
                i
            );
            uint256 tem = 0;
            (mathErr, tem) = mulUInt(balance, stream2.nftShares[tokenId]);
            (mathErr, tem) = divUInt(tem, 1e12);
            stream2s[stream2Id].claimedAmount[tokenId] += tem;
            // investorWithdrawalAmount[streamId][tokenId] += withdrawAmountPerNFT;
        }
        /**
         * `subUInt` can only return MathError.INTEGER_UNDERFLOW but we know that `remainingBalance` is at least
         * as big as `amount`.
         */
        assert(mathErr == MathError.NO_ERROR);

        // if (stream2s[stream2Id].remainingBalance == 0)
        //     delete stream2s[stream2Id];

        uint256 remainingBalance = IERC20(stream2.tokenAddress).balanceOf(
            address(this)
        );
        if (balance > remainingBalance) {
            IERC20(stream2.tokenAddress).safeTransfer(
                msg.sender,
                remainingBalance
            );
        } else {
            IERC20(stream2.tokenAddress).safeTransfer(msg.sender, balance);
        }
        emit WithdrawFromStream2(stream2Id, msg.sender, balance);
        return true;
    }

    function senderWithdrawFromStream2(uint256 stream2Id)
        external
        nonReentrant
        stream2Exists(stream2Id)
        onlySenderOrRecipient2(stream2Id)
        returns (bool)
    {
        VestingTypes.VestingStream2 storage stream2 = stream2s[stream2Id];
        require(msg.sender == stream2.sender, "Vesting: Permission Deny");
        require(
            block.timestamp >= stream2.stopTime,
            "Sender withdraw Error: block timestamp < stoptime"
        );
        uint256 balance = balanceOfSender2(stream2Id);
        require(balance > 0, "Sender Withdrawable Balance Is Zero");

        MathError mathErr;

        (mathErr, stream2s[stream2Id].remainingBalance) = subUInt(
            stream2.remainingBalance,
            balance
        );

        /**
         * `subUInt` can only return MathError.INTEGER_UNDERFLOW but we know that `remainingBalance` is at least
         * as big as `amount`.
         */
        assert(mathErr == MathError.NO_ERROR);

        IERC20(stream2.tokenAddress).safeTransfer(msg.sender, balance);
        if (stream2s[stream2Id].remainingBalance == 0)
            delete stream2s[stream2Id];
        return true;
    }
}
