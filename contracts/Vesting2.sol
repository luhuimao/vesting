pragma solidity ^0.8.0;
import "./openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./shared-contracts/compound/CarefulMath.sol";
import "./interfaces/IVesting2.sol";
import "./Types.sol";
import "./ERC721.sol";
import "./test/testNFT.sol";
import "hardhat/console.sol";

/**
 * @title Vesting
 * @author Benjamin
 * @notice Money streaming.
 */
contract Vesting2 is IVesting2, ReentrancyGuard, CarefulMath {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using VestingTypes for VestingTypes.VestingStream;
    /*** Storage Properties ***/

    /**
     * @notice Counter for new stream2 ids.
     */
    uint256 public nextStream2Id;
    /**
     * @notice The stream2 objects identifiable by their unsigned integer ids.
     */
    mapping(uint256 => VestingTypes.VestingStream2) private stream2s;
    // streamID -> tokenID -> withdrawAmount
    mapping(uint256 => mapping(uint256 => uint256))
        private investorWithdrawalAmount;

    /*** Modifiers ***/

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

    /**
     * @dev Throws if the caller is not the owner of the spacified tokenId of the stream2.
     */
    modifier onlyNFTOwner(uint256 stream2Id, uint256 tokenId) {
        address nftAddress = stream2s[stream2Id].erc721Address;
        require(
            msg.sender == ERC721(nftAddress).ownerOf(tokenId),
            "caller is not the owner of the tokenId"
        );
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
        nextStream2Id = 200000;
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

        uint256 totalBalance = 0;
        address nftAddress = stream2.erc721Address;
        uint256 nftBalance = ERC721(nftAddress).balanceOf(who);
        if (nftBalance > 0) {
            for (uint256 j = 0; j < nftBalance; j++) {
                //for loop
                uint256 tokenId = ERC721(stream2.erc721Address)
                    .tokenOfOwnerByIndex(who, j);

                uint256 balance = availableBalanceForTokenId(stream2Id, tokenId);
                totalBalance += balance;
            }
            return totalBalance;
        }
        return 0;
    }

    /*
     * @notice Returns the available funds for the given stream2 id and tokenId.
     * @dev Throws if the id does not point to a valid stream2.
     * @param stream2Id The id of the stream for which to query the balance.
     * @param tokenId The tokenId for which to query the balance.
     * @return The available funds allocated to `tokenId` owner as uint256.
     */
    function availableBalanceForTokenId(uint256 stream2Id, uint256 tokenId)
        public
        view
        stream2Exists(stream2Id)
        returns (uint256)
    {
        VestingTypes.VestingStream2 storage stream2 = stream2s[stream2Id];
        uint256 delta = deltaOf2(stream2Id);
        uint256 totalBalance = delta.mul(stream2.ratePerSecond);
        uint256 share = stream2.nftShares[tokenId];

        uint256 tokenidBalance = totalBalance
            .mul(share)
            .div(stream2.totalShares)
            .sub(stream2.claimedAmount[tokenId]);
        return tokenidBalance;
    }

    function remainingBalanceByTokenId(uint256 stream2Id, uint256 tokenId)
        public
        view
        returns (uint256)
    {
        VestingTypes.VestingStream2 storage stream2 = stream2s[stream2Id];
        uint256 steramDuration = stream2.stopTime - stream2.startTime;

        uint256 totalBalance = steramDuration.mul(stream2.ratePerSecond);
        uint256 share = stream2.nftShares[tokenId];
        uint256 tokenidBalance = totalBalance
            .mul(share)
            .div(stream2.totalShares)
            .sub(stream2.claimedAmount[tokenId]);

        return tokenidBalance;
    }

    function balanceOfSender2(uint256 stream2Id)
        public
        view
        stream2Exists(stream2Id)
        returns (uint256 balance)
    {
        VestingTypes.VestingStream2 storage stream2 = stream2s[stream2Id];
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
    function createStream2(
        uint256 deposit,
        address tokenAddress,
        uint256 startTime,
        uint256 stopTime,
        address erc721Address,
        uint256[] memory tokenIds,
        uint256[] memory nftShares
    ) public returns (uint256) {
        require(erc721Address != address(0x00), "nftAddress is zero address");
        require(deposit > 0, "deposit is zero");
        require(nftShares.length > 0, "nftShares length is zero");
        require(tokenIds.length > 0, "tokenIds length is zero");
        require(
            tokenIds.length == nftShares.length,
            "nftShares length is not equal tokenIds length"
        );
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
        // require(
        //     deposit % vars.duration == 0,
        //     "deposit not multiple of time delta"
        // );

        (vars.mathErr, vars.ratePerSecond) = divUInt(deposit, vars.duration);
        /* `divUInt` can only return MathError.DIVISION_BY_ZERO but we know `duration` is not zero. */
        assert(vars.mathErr == MathError.NO_ERROR);

        /* Create and store the stream2 object. */
        uint256 stream2Id = nextStream2Id;
        uint256 totalShares = 0;
        for (uint256 i = 0; i < nftShares.length; i++) {
            (vars.mathErr, totalShares) = addUInt(totalShares, nftShares[i]);
            assert(vars.mathErr == MathError.NO_ERROR);
        }

        for (uint256 i = 0; i < nftShares.length; i++) {
            stream2s[stream2Id].nftShares[tokenIds[i]] = nftShares[i];
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
        stream2s[stream2Id].totalShares = totalShares;

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

        uint256 remainingBalance = stream2.remainingBalance;
        stream2s[stream2Id].remainingBalance = remainingBalance.sub(balance);

        uint256 realBalance = 0;
        for (uint256 i = 0; i < getNFTBalance2(stream2Id, msg.sender); i++) {
            uint256 tokenId = ERC721(stream2.erc721Address).tokenOfOwnerByIndex(
                msg.sender,
                i
            );
            uint256 balanceOfTokenId = availableBalanceForTokenId(stream2Id, tokenId);
            realBalance += balanceOfTokenId;

            stream2s[stream2Id].claimedAmount[tokenId] += balanceOfTokenId;
        }
        require(realBalance == balance, "Vesting ERROR");
        /**
         * `subUInt` can only return MathError.INTEGER_UNDERFLOW but we know that `remainingBalance` is at least
         * as big as `amount`.
         */

        // if (stream2s[stream2Id].remainingBalance == 0)
        //     delete stream2s[stream2Id];

        uint256 vaultRemainingBalance = IERC20(stream2.tokenAddress).balanceOf(
            address(this)
        );
        if (balance > vaultRemainingBalance) {
            IERC20(stream2.tokenAddress).safeTransfer(
                msg.sender,
                vaultRemainingBalance
            );
        } else {
            IERC20(stream2.tokenAddress).safeTransfer(msg.sender, balance);
        }
        emit WithdrawFromStream2(stream2Id, msg.sender, balance);
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
    function withdrawFromStream2ByTokenId(uint256 stream2Id, uint256 tokenId)
        external
        override
        nonReentrant
        stream2Exists(stream2Id)
        onlyNFTOwner(stream2Id, tokenId)
        returns (bool)
    {
        VestingTypes.VestingStream2 storage stream2 = stream2s[stream2Id];

        require(
            block.timestamp < stream2.stopTime,
            "Withdraw Error: streaming is ends"
        );

        uint256 balance = availableBalanceForTokenId(stream2Id, tokenId);

        require(balance > 0, "withdrawable balance is zero");

        uint256 remainingBalance = stream2.remainingBalance;
        stream2s[stream2Id].remainingBalance = remainingBalance.sub(balance);

        stream2s[stream2Id].claimedAmount[tokenId] += balance;

        uint256 vaultRemainingBalance = IERC20(stream2.tokenAddress).balanceOf(
            address(this)
        );
        if (balance > vaultRemainingBalance) {
            IERC20(stream2.tokenAddress).safeTransfer(
                msg.sender,
                vaultRemainingBalance
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
        // if (stream2s[stream2Id].remainingBalance == 0)
        //     delete stream2s[stream2Id];
        return true;
    }
}
