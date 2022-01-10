// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./shared-contracts/compound/CarefulMath.sol";
import "./interfaces/ISablier.sol";
import "./Types.sol";
import "./ERC721.sol";
import "hardhat/console.sol";

/**
 * @title Sablier
 * @author Sablier
 * @notice Money streaming.
 */
contract Sablier is ISablier, ReentrancyGuard, CarefulMath {
    using SafeERC20 for IERC20;

    /*** Storage Properties ***/

    /**
     * @notice Counter for new stream ids.
     */
    uint256 public nextStreamId;

    /**
     * @notice The stream objects identifiable by their unsigned integer ids.
     */
    mapping(uint256 => Types.Stream) private streams;

    mapping(uint256 => mapping(address => uint256)) private investorWithdrawalAmount;
    /*** Modifiers ***/

    /**
     * @dev Throws if the caller is not the sender of the recipient of the stream.
     */
    modifier onlySenderOrRecipient(uint256 streamId) {
        // require(
        //     msg.sender == streams[streamId].sender ||
        //         msg.sender == streams[streamId].recipient,
        //     "caller is not the sender or the recipient of the stream"
        // );
        require(
            msg.sender == streams[streamId].sender || isHistoriesOwnerOfNFT(streamId, msg.sender),
            "caller is not the sender or the recipient of the stream"
        );
        _;
    }

    /**
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
            // address recipient,
            uint256 deposit,
            address tokenAddress,
            uint256 startTime,
            uint256 stopTime,
            uint256 remainingBalance,
            uint256 ratePerSecond,
            address erc721Address, 
            uint256 tokenId
        )
    {
        sender = streams[streamId].sender;
        // recipient = streams[streamId].recipient;
        deposit = streams[streamId].deposit;
        tokenAddress = streams[streamId].tokenAddress;
        startTime = streams[streamId].startTime;
        stopTime = streams[streamId].stopTime;
        remainingBalance = streams[streamId].remainingBalance;
        ratePerSecond = streams[streamId].ratePerSecond;
        erc721Address = streams[streamId].erc721Address;
        tokenId= streams[streamId].tokenId;
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
        Types.Stream memory stream = streams[streamId];
        if (block.timestamp <= stream.startTime) return 0;
        if (block.timestamp < stream.stopTime)
            return block.timestamp - stream.startTime;
        return stream.stopTime - stream.startTime;
    }

    function deltaOfHistoriesOwner(uint256 streamId, address who)
        public
        view
        streamExists(streamId)
        returns (uint256 del)
    {
        Types.Stream memory stream = streams[streamId];
        address nftAddress = stream.erc721Address;
        uint256 tokenId= stream.tokenId;
        (uint256 startOwnedTimeStamp, uint256 endOwnedTimeStamp)= ERC721(nftAddress).getHistoriesOwnedTimeStamp(tokenId,who);
        // console.log("startOwnedTimeStamp of ", who, ": ", startOwnedTimeStamp);
        // console.log("endOwnedTimeStamp of ", who, ": ", endOwnedTimeStamp);
        // console.log("stream.startTime: ", stream.startTime);
        // console.log("stream.stopTime: ", stream.stopTime);
        // console.log("block.timestamp: ", block.timestamp);
        //streaming not start yet
        if (block.timestamp <= stream.startTime) return 0;
        if (startOwnedTimeStamp == 0) return 0;
        //endOwnedTimeStamp smaller than stream.startTime
        if(endOwnedTimeStamp > 0 && endOwnedTimeStamp <= stream.startTime) return 0;
        //startOwnedTimeStamp greater than stream.stopTime
        if(startOwnedTimeStamp >= stream.stopTime) return 0;
        //who is the current owner
        if(endOwnedTimeStamp == 0){
            //streaming not finish
            if (block.timestamp < stream.stopTime){
                //case #1.
                if (startOwnedTimeStamp <= stream.startTime)
                    return block.timestamp - stream.startTime;
                //case #2.
                if(startOwnedTimeStamp >= stream.startTime &&
                    startOwnedTimeStamp < block.timestamp 
                )
                    return block.timestamp - startOwnedTimeStamp;
                //case #3.
                if(startOwnedTimeStamp > block.timestamp)
                    return 0;
            }else{// streaming finished.
                //case #7.
                if (startOwnedTimeStamp <= stream.startTime)
                    return stream.stopTime - stream.startTime;
                //case #8.
                if(startOwnedTimeStamp > stream.startTime &&
                    startOwnedTimeStamp <= stream.stopTime 
                )
                    return stream.stopTime - startOwnedTimeStamp;
                //case #10.
                if(startOwnedTimeStamp > stream.startTime &&
                    endOwnedTimeStamp <= stream.stopTime &&
                    endOwnedTimeStamp <= block.timestamp 
                )
                    return endOwnedTimeStamp - startOwnedTimeStamp;
                //case #11.
                if(startOwnedTimeStamp > stream.stopTime)
                    return 0;
            }
        }else{
            //streaming not finish
            if (block.timestamp < stream.stopTime){
                //case #1.
                if (startOwnedTimeStamp <= stream.startTime &&
                    endOwnedTimeStamp <= block.timestamp &&
                    endOwnedTimeStamp <= stream.stopTime &&
                    endOwnedTimeStamp > 0
                )
                    return endOwnedTimeStamp - stream.startTime;
                //case #2.
                if (startOwnedTimeStamp <= stream.startTime &&
                    endOwnedTimeStamp > block.timestamp &&
                    endOwnedTimeStamp <= stream.stopTime &&
                    endOwnedTimeStamp > 0
                )
                    return block.timestamp - stream.startTime;
                //case #3.
                if(startOwnedTimeStamp > stream.startTime &&
                    endOwnedTimeStamp < stream.stopTime &&
                    endOwnedTimeStamp < block.timestamp &&
                    endOwnedTimeStamp > 0
                )
                    return endOwnedTimeStamp - startOwnedTimeStamp;
                //case #4.
                if(startOwnedTimeStamp > stream.startTime &&
                    endOwnedTimeStamp < stream.stopTime &&
                    endOwnedTimeStamp > block.timestamp &&
                    endOwnedTimeStamp > 0
                )
                    return block.timestamp - startOwnedTimeStamp;
                //case #5.
                if(startOwnedTimeStamp > stream.startTime &&
                    startOwnedTimeStamp < block.timestamp &&
                    endOwnedTimeStamp > block.timestamp &&
                    endOwnedTimeStamp > stream.stopTime &&
                    endOwnedTimeStamp > 0
                )
                    return block.timestamp - startOwnedTimeStamp;
                //case #6.
                if(startOwnedTimeStamp > stream.startTime &&
                    startOwnedTimeStamp > block.timestamp &&
                    endOwnedTimeStamp > block.timestamp &&
                    endOwnedTimeStamp > stream.stopTime &&
                    endOwnedTimeStamp > 0
                )
                    return 0;
            }else{// streaming finished.
                //case #7.
                if (startOwnedTimeStamp <= stream.startTime &&
                    endOwnedTimeStamp <= block.timestamp &&
                    endOwnedTimeStamp <= stream.stopTime
                )
                    return endOwnedTimeStamp - stream.startTime;
                //case #8.
                if (startOwnedTimeStamp <= stream.startTime &&
                    endOwnedTimeStamp >= stream.stopTime &&
                    endOwnedTimeStamp <= block.timestamp
                )
                    return stream.stopTime - stream.startTime;
                //case #9.
                if(startOwnedTimeStamp > stream.startTime &&
                    endOwnedTimeStamp > stream.stopTime &&
                    stream.stopTime <= block.timestamp 
                )
                    return endOwnedTimeStamp - startOwnedTimeStamp;
                //case #10.
                if(startOwnedTimeStamp > stream.startTime &&
                    endOwnedTimeStamp <= stream.stopTime &&
                    endOwnedTimeStamp <= block.timestamp 
                )
                    return endOwnedTimeStamp - startOwnedTimeStamp;
                //case #11.
                if(startOwnedTimeStamp > stream.stopTime)
                    return 0;
            }
        }

    }

    function getERC721HistoriesOwners(uint256 streamId)
        public 
        view 
        streamExists(streamId)
        returns (address[] memory)
    {
        Types.Stream memory stream = streams[streamId];
        address nftAddress = stream.erc721Address;
        uint256 tokenId= stream.tokenId;
        return ERC721(nftAddress).getAllHistoriesOwner(tokenId);
        
    }
    
    function isHistoriesOwnerOfNFT(uint256 streamId, address who)
        internal 
        view         
        streamExists(streamId)
        returns(bool)
    {
        Types.Stream memory stream = streams[streamId];
        require(stream.sender != who, "stream recipient is stream sender");
        address nftAddress = stream.erc721Address;
        uint256 tokenId= stream.tokenId;
        return ERC721(nftAddress).transferredHistoriesExists(tokenId,who);
    }

    // function getOwnedTimeStamp(uint256 streamId, address who)internal 
    //     view         
    //     streamExists(streamId)
    //     returns (uint256 startOwneredTimeStamp, uint256 endOwneredTimeStamp)
    // {
    //     Types.Stream memory stream = streams[streamId];
    //     address nftAddress = stream.erc721Address;
    //     uint256 tokenId= stream.tokenId;
    //     return ERC721(nftAddress)._getHistoriesOwnedTimeStamp(tokenId,who);

    // }

    function _historiesOwnerAmountOfNFT(uint256 streamId)   
        internal 
        view         
        streamExists(streamId)
        returns(uint256)
    {
        Types.Stream memory stream = streams[streamId];
        address nftAddress = stream.erc721Address;
        uint256 tokenId= stream.tokenId;
        return ERC721(nftAddress).totalTransferredCount(tokenId);
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
        Types.Stream memory stream = streams[streamId];
        BalanceOfLocalVars memory vars;

        uint256 delta = deltaOf(streamId);
        console.log("stream.ratePerSecond: ", stream.ratePerSecond);
        (vars.mathErr, vars.recipientBalance) = mulUInt(
            delta,
            stream.ratePerSecond
        );
        // console.log(" vars.recipientBalance", vars.recipientBalance);
        // console.log("stream.remainingBalance: ", stream.remainingBalance);
        require(
            vars.mathErr == MathError.NO_ERROR,
            "recipient balance calculation error"
        );

        /*
         * If the stream `balance` does not equal `deposit`, it means there have been withdrawals.
         * We have to subtract the total amount withdrawn from the amount of money that has been
         * streamed until now.
         */
        if (stream.deposit > stream.remainingBalance) {
            console.log("stream.deposit > stream.remainingBalance");
            (vars.mathErr, vars.withdrawalAmount) = subUInt(
                stream.deposit,
                stream.remainingBalance
            );
            assert(vars.mathErr == MathError.NO_ERROR);
            (vars.mathErr, vars.recipientBalance) = subUInt(
                vars.recipientBalance,
                vars.withdrawalAmount
            );
            /* `withdrawalAmount` cannot and should not be bigger than `recipientBalance`. */
            assert(vars.mathErr == MathError.NO_ERROR);
        }
        // if who use to be owner of tokenId
        if(isHistoriesOwnerOfNFT(streamId, who)){
            // console.log("isHistoriesOwnerOfNFT");
            uint256 deltasOfHistoriesOwner = deltaOfHistoriesOwner(streamId, who);
            console.log("deltaOfHistoriesOwner: ", deltasOfHistoriesOwner);
            (MathError matherr, uint256 investorBalance) = mulUInt(deltasOfHistoriesOwner, stream.ratePerSecond);
            assert(vars.mathErr == MathError.NO_ERROR);
            uint256 withdrawralAmount = investorWithdrawalAmount[streamId][who];
            (matherr, investorBalance) = subUInt(investorBalance,withdrawralAmount);
            assert(vars.mathErr == MathError.NO_ERROR);
            return investorBalance;
        }
        // if (who == stream.recipient) return vars.recipientBalance;
        if (who == stream.sender) {
            (vars.mathErr, vars.senderBalance) = subUInt(
                stream.remainingBalance,
                vars.recipientBalance
            );
            /* `recipientBalance` cannot and should not be bigger than `remainingBalance`. */
            assert(vars.mathErr == MathError.NO_ERROR);
            return vars.senderBalance;
        }
        return 0;
    }

    /*** Public Effects & Interactions Functions ***/

    struct CreateStreamLocalVars {
        MathError mathErr;
        uint256 duration;
        uint256 ratePerSecond;
    }

    /**
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
     * param recipient The address towards which the money is streamed.
     * @param deposit The amount of money to be streamed.
     * @param tokenAddress The ERC20 token to use as streaming currency.
     * @param startTime The unix timestamp for when the stream starts.
     * @param stopTime The unix timestamp for when the stream stops.
     * @param erc721Address The ERC721 address.
     * @param tokenId The tokenID.
     * @return The uint256 id of the newly created stream.
     */
    function createStream(
        // address recipient,
        uint256 deposit,
        address tokenAddress,
        uint256 startTime,
        uint256 stopTime,
        address erc721Address,
        uint256 tokenId
    ) public override returns (uint256) {
        // require(recipient != address(0x00), "stream to the zero address");
        // require(recipient != address(this), "stream to the contract itself");
        // require(recipient != msg.sender, "stream to the caller");
        require(
            erc721Address != address(0x00),
            "stream to the zero ERC721 address"
        );
        require(
            erc721Address != address(this),
            "stream to the contract itself"
        );

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

        /* Create and store the stream object. */
        uint256 streamId = nextStreamId;
        streams[streamId] = Types.Stream({
            remainingBalance: deposit,
            deposit: deposit,
            isEntity: true,
            ratePerSecond: vars.ratePerSecond,
            // recipient: recipient,
            sender: msg.sender,
            startTime: startTime,
            stopTime: stopTime,
            tokenAddress: tokenAddress,
            tokenId:tokenId,
            erc721Address:erc721Address
        });

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
            // recipient,
            deposit,
            tokenAddress,
            startTime,
            stopTime,
            erc721Address,
            tokenId
        );
        // console.log("streamId:", streamId);
        return streamId;
    }

    /**
     * @notice Withdraws from the contract to the recipient's account.
     * @dev Throws if the id does not point to a valid stream.
     *  Throws if the caller is not the sender or the recipient of the stream.
     *  Throws if the amount exceeds the available balance.
     *  Throws if there is a token transfer failure.
     * @param streamId The id of the stream to withdraw tokens from.
     * @param amount The amount of tokens to withdraw.
     */
    function withdrawFromStream(uint256 streamId, uint256 amount)
        external
        override
        nonReentrant
        streamExists(streamId)
        onlySenderOrRecipient(streamId)
        returns (bool)
    {
        require(amount > 0, "amount is zero");
        Types.Stream memory stream = streams[streamId];

        // uint256 balance = balanceOf(streamId, stream.recipient);
        uint256 balance = balanceOf(streamId, msg.sender);
        require(balance >= amount, "amount exceeds the available balance");
        console.log("before withdraw stream remainingBalance: ", stream.remainingBalance);
        MathError mathErr;
        (mathErr, streams[streamId].remainingBalance) = subUInt(
            stream.remainingBalance,
            amount
        );
        console.log("after withdraw stream remainingBalance: ", streams[streamId].remainingBalance);

        investorWithdrawalAmount[streamId][msg.sender] = amount;
        /**
         * `subUInt` can only return MathError.INTEGER_UNDERFLOW but we know that `remainingBalance` is at least
         * as big as `amount`.
         */
        assert(mathErr == MathError.NO_ERROR);

        if (streams[streamId].remainingBalance == 0) delete streams[streamId];

        // IERC20(stream.tokenAddress).safeTransfer(stream.recipient, amount);
        IERC20(stream.tokenAddress).safeTransfer(msg.sender, amount);

        // emit WithdrawFromStream(streamId, stream.recipient, amount);
        emit WithdrawFromStream(streamId, msg.sender, amount);

        return true;
    }

    /**
     * @notice Cancels the stream and transfers the tokens back on a pro rata basis.
     * @dev Throws if the id does not point to a valid stream.
     *  Throws if the caller is not the sender or the recipient of the stream.
     *  Throws if there is a token transfer failure.
     * @param streamId The id of the stream to cancel.
     * @return bool true=success, otherwise false.
     */
    function cancelStream(uint256 streamId)
        external
        override
        nonReentrant
        streamExists(streamId)
        onlySenderOrRecipient(streamId)
        returns (bool)
    {
        Types.Stream memory stream = streams[streamId];
        uint256 senderBalance = balanceOf(streamId, stream.sender);
        IERC20 token = IERC20(stream.tokenAddress);
        address verifiedRecipient;
        uint256 recipientBalance;
        address[] memory historiesOwners = getERC721HistoriesOwners(streamId);
        uint i = 0;
        uint len = historiesOwners.length;
        for(i; i < len; i += 1){
            verifiedRecipient = historiesOwners[i];
            recipientBalance = balanceOf(streamId, verifiedRecipient);

            if (recipientBalance > 0)
                token.safeTransfer(verifiedRecipient, recipientBalance);
        }
        if (senderBalance > 0) token.safeTransfer(stream.sender, senderBalance);

        delete streams[streamId];
        // emit CancelStream(
        //     streamId,
        //     stream.sender,
        //     stream.recipient,
        //     senderBalance,
        //     recipientBalance
        // );
         emit CancelStream(
            streamId,
            stream.sender,
            verifiedRecipient,
            senderBalance,
            recipientBalance
        );
        return true;
    }
}
