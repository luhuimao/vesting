pragma solidity ^0.8.0;
import "./openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./shared-contracts/compound/CarefulMath.sol";
import "./interfaces/IStream1MultiNFTV2.sol";
import "./Types.sol";
import "./Library/Stream1LibV2.sol";
// import "./ERC721.sol";
// import "./test/testNFT.sol";
import "./openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./ERC721Stream1V2.sol";
import "hardhat/console.sol";

/**
 * @title Vesting
 * @author Benjamin
 * @notice Money streaming.
 */
contract Stream1MultiNFTV2 is IStream1MultiNFTV2, ReentrancyGuard, CarefulMath {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using Stream1LibV2 for Stream1LibV2.VestingStream1;
    using EnumerableSet for EnumerableSet.UintSet;

    /*** Storage Properties ***/

    /**
     * @notice Counter for new stream ids.
     */
    uint256 public nextStreamId;

    address public erc721Address;
    /**
     * @notice The stream objects identifiable by their unsigned integer ids.
     */

    mapping(uint256 => Stream1LibV2.VestingStream1) private streams1;
    mapping(uint256 => EnumerableSet.UintSet) private effectedTokenIds;
    mapping(address => mapping(uint256 => uint256)) userAvailableBalance;
    /*** Modifiers ***/

    modifier onlySender(uint256 streamId) {
        require(
            msg.sender == streams1[streamId].sender,
            "caller is not the sender of the stream"
        );
        _;
    }

    /**
     * @dev Throws if the caller is not the owner of the spacified tokenId of the stream2.
     */
    modifier onlyNFTOwner(uint256 tokenId) {
        require(
            msg.sender == ERC721(erc721Address).ownerOf(tokenId),
            "caller is not the owner of the tokenId"
        );
        _;
    }

    /*
     * @dev Throws if the provided id does not point to a valid stream.
     */
    modifier streamExists(uint256 streamId) {
        require(streams1[streamId].isEntity, "stream does not exist");
        _;
    }

    /*** Contract Logic Starts Here */

    constructor(address _erc721Addr) {
        nextStreamId = 100000;
        erc721Address = _erc721Addr;
    }

    /*** View Functions ***/
    /*
     * @notice Returns the stream with all its properties.
     * @dev Throws if the id does not point to a valid stream.
     * @param streamId The id of the stream to query.
     * @return The stream object.
     */
    function getStreamInfo(uint256 streamId)
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
            uint256 remainingBalance
        )
    {
        sender = streams1[streamId].sender;
        deposit = streams1[streamId].deposit;
        tokenAddress = streams1[streamId].tokenAddress;
        startTime = streams1[streamId].startTime;
        stopTime = streams1[streamId].stopTime;
        remainingBalance = streams1[streamId].remainingBalance;
    }

    function getStreamSupportedTokenIds(uint256 streamId)
        external
        view
        streamExists(streamId)
        returns (uint256[] memory)
    {
        return streams1[streamId].tokenIdValues();
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
        Stream1LibV2.VestingStream1 storage stream = streams1[streamId];
        if (block.timestamp <= stream.startTime) return 0;
        if (block.timestamp < stream.stopTime)
            return block.timestamp - stream.startTime;
        return stream.stopTime - stream.startTime;
    }

    struct BalanceOfLocalVars {
        uint256 recipientBalance;
        uint256 withdrawalAmount;
        uint256 senderBalance;
        uint256 individualBalance;
        uint256 counter;
        uint256 i;
        uint256 j;
    }

    /*
     * @notice Returns the available funds for the given stream id and address.
     * @dev Throws if the id does not point to a valid stream.
     * @param streamId The id of the stream for which to query the balance.
     * @param who The address for which to query the balance.
     * @return The total funds allocated to `who` as uint256.
     */
    function availableBalanceForAllNft(
        uint256 streamId,
        address who,
        uint256[] calldata tokenIds
    ) external override streamExists(streamId) returns (uint256 balance) {
        Stream1LibV2.VestingStream1 storage stream = streams1[streamId];
        BalanceOfLocalVars memory vars;
        if (tokenIds.length <= 0) {
            return 0;
        }
        // uint256[] memory _dededuplicateTokenIds = tokenIdsDeduplicate(tokenIds);
        vars.recipientBalance = 0;
        for (vars.j = 0; vars.j < tokenIds.length; vars.j++) {
            if (
                stream.existsTokenId(tokenIds[vars.j]) &&
                IERC721(stream.erc721Address).ownerOf(tokenIds[vars.j]) ==
                who &&
                !effectedTokenIds[block.timestamp].contains(tokenIds[vars.j])
            ) {
                // console.log("Contract Log => who: ", who);
                // console.log(
                //     "Contract Log => valid tokenId: ",
                //     tokenIds[vars.j]
                // );
                effectedTokenIds[block.timestamp].add(tokenIds[vars.j]);
                vars.individualBalance = availableBalanceForTokenId(
                    streamId,
                    tokenIds[vars.j]
                );

                vars.recipientBalance += vars.individualBalance;
            }
        }
        delete effectedTokenIds[block.timestamp];
        // console.log(
        //     "Constract Log => vars.recipientBalance: ",
        //     vars.recipientBalance
        // );
        userAvailableBalance[who][streamId] = vars.recipientBalance;
        // console.log(
        //     "Contract Log: ",
        //     who,
        //     " available balance: ",
        //     userAvailableBalance[who][streamId]
        // );
        return vars.recipientBalance;
    }

    function getUserAllAvailableBalance(uint256 streamId, address who)
        external
        view
        returns (uint256)
    {
        return userAvailableBalance[who][streamId];
    }

    function availableBalanceForTokenId(uint256 streamId, uint256 tokenId)
        public
        view
        streamExists(streamId)
        returns (uint256 balance)
    {
        Stream1LibV2.VestingStream1 storage stream = streams1[streamId];
        BalanceOfLocalVars memory vars;

        if (!stream.existsTokenId(tokenId)) {
            return 0;
        }
        // console.log(
        //     "contract log availableBalanceForTokenId => satisfied nft address: ",
        //     nftAddress,
        //     " satisfied tokenId: ",
        //     tokenId
        // );
        uint256 delta = deltaOf(streamId);
        // console.log(
        //     "contract log  availableBalanceForTokenId => delta: ",
        //     delta
        // );
        // console.log(
        //     "Constract Log => tokenIdRatePerSec: ",
        //     stream.tokenIdRatePerSec[tokenId]
        // );
        uint256 totalBalance = delta.mul(stream.tokenIdRatePerSec[tokenId]);
        // console.log(
        //     "contract log  availableBalanceForTokenId => totalBalance: ",
        //     totalBalance
        // );
        vars.recipientBalance = 0;
        // console.log(
        //     "contract log availableBalanceForTokenId => NFTTokenIdWithdrawalAmount: ",
        //     stream.NFTTokenIdWithdrawalAmount[nftAddress][tokenId]
        // );
        vars.recipientBalance = totalBalance.sub(
            stream.NFTTokenIdWithdrawalAmount[tokenId]
        );

        // console.log(
        //     "Contract Log => tokenId: ",
        //     tokenId,
        //     " recipientBalance: ",
        //     vars.recipientBalance
        // );

        return vars.recipientBalance;
    }

    function remainingBalanceByTokenId(uint256 streamId, uint256 tokenId)
        public
        view
        streamExists(streamId)
        returns (uint256)
    {
        Stream1LibV2.VestingStream1 storage stream = streams1[streamId];

        if (!stream.existsTokenId(tokenId)) {
            return 0;
        }
        uint256 streamDuration = stream.stopTime.sub(stream.startTime);
        // console.log(
        //     "Contract Log => stream.tokenIdRatePerSec[tokenId] ",
        //     stream.tokenIdRatePerSec[tokenId]
        // );
        uint256 totalBalance = streamDuration.mul(
            stream.tokenIdRatePerSec[tokenId]
        );
        // console.log("Contract Log => totalBalance ", totalBalance);

        uint256 tokenidBalance = totalBalance.sub(
            stream.NFTTokenIdWithdrawalAmount[tokenId]
        );
        // console.log("Contract Log => tokenidBalance ", tokenidBalance);

        return tokenidBalance;
    }

    function balanceOfSender(uint256 streamId)
        public
        view
        streamExists(streamId)
        returns (uint256 balance)
    {
        return streams1[streamId].remainingBalance;
    }

    function getTokenRatePerSec(uint256 streamId, uint256 tokenId)
        external
        view
        returns (uint256)
    {
        return streams1[streamId].tokenIdRatePerSec[tokenId];
    }

    /*** Public Effects & Interactions Functions ***/

    struct CreateStreamLocalVars {
        uint256 duration;
        uint256 ratePerSecond;
        uint256 totalDuration;
        uint256 nftTotalSupply;
        uint256 vaultRemainingBalance;
        uint256 allAvailableBalance;
        uint256 i;
        uint256 streamAmount;
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
    function createMultiNFTStream(
        uint256[3] calldata _uintArgs, //_uintArgs[0] deposit, _uintArgs[1] startTime, _uintArgs[2] stopTime
        address tokenAddress,
        uint256[] calldata _uint256ArgsNFTSupply,
        uint256[] calldata _uint256ArgsNFTShares
    ) external override returns (uint256) {
        CreateStreamLocalVars memory cvars;
        require(
            _uintArgs[1] >= block.timestamp,
            "start time before block.timestamp"
        );

        require(_uintArgs[2] > _uintArgs[1], "stop time before the start time");

        uint256 streamId = nextStreamId;

        uint256[2] memory uintValues = [
            // _uintArgs[0], //deposit
            // _uintArgs[0], //remainingBalance
            _uintArgs[1], //startTime
            _uintArgs[2] //stopTime
        ];

        address[3] memory addressValues = [
            msg.sender, //sender
            tokenAddress, //tokenAddress
            erc721Address //erc721Address
        ];

        /* Create and store the stream object. */
        streams1[streamId].addStream1(uintValues, addressValues, true);
        cvars.duration = _uintArgs[2].sub(_uintArgs[1]);

        if (
            _uint256ArgsNFTSupply.length > 0 || _uint256ArgsNFTShares.length > 0
        ) {
            require(
                _uint256ArgsNFTSupply.length == _uint256ArgsNFTShares.length,
                "ERROR: Mint NFT Amount Not Matach NFT Shares"
            );
            for (
                cvars.i = 0;
                cvars.i < _uint256ArgsNFTSupply.length;
                cvars.i++
            ) {
                cvars.streamAmount += _uint256ArgsNFTSupply[cvars.i].mul(
                    _uint256ArgsNFTShares[cvars.i]
                );
                cvars.nftTotalSupply += _uint256ArgsNFTSupply[cvars.i];

                /* Without this, the rate per second would be zero. */
                require(
                    _uint256ArgsNFTShares[cvars.i] >= cvars.duration,
                    "nft share smaller than time delta"
                );

                cvars.ratePerSecond = _uint256ArgsNFTShares[cvars.i].div(
                    cvars.duration
                );
                // console.log(
                //     "Contract Log => totalSupply: ",
                //     ERC721Stream1V2(erc721Address).totalSupply()
                // );

                streams1[streamId].updateStream1(
                    ERC721Stream1V2(erc721Address).totalSupply(),
                    _uint256ArgsNFTSupply[cvars.i],
                    _uint256ArgsNFTShares[cvars.i],
                    cvars.ratePerSecond
                );

                //mint ERC721 to sender
                ERC721Stream1V2(erc721Address).mint(
                    _uint256ArgsNFTSupply[cvars.i],
                    msg.sender
                );
            }

            require(
                _uintArgs[0] >= cvars.streamAmount,
                "ERROR: Deposit Amount Insufficient"
            );

            // console.log("Contract Log =>  vars.duration ", vars.duration);

            // cvars.totalDuration = cvars.duration.mul(
            //     _uint256ArgsNFTSupply[cvars.i]
            // );
            // console.log("Contract Log =>  vars.totalDuration ", vars.totalDuration);

            // console.log("Contract Log =>  vars.ratePerSecond ", vars.ratePerSecond);

            IERC20(tokenAddress).safeTransferFrom(
                msg.sender,
                address(this),
                _uintArgs[0] // deposit
            );

            streams1[streamId].depositToken(_uintArgs[0]);
        }

        /* Increment the next stream id. */
        nextStreamId = nextStreamId.add(uint256(1));

        emit CreateStream(
            streamId,
            msg.sender
            // _uintArgs[0], // deposit,
            // tokenAddress,
            // _uintArgs[1], // startTime,
            // _uintArgs[2], // stopTime,
            // erc721Address
        );
        return streamId;
    }

    // function updateStream(
    //     uint256 streamId,
    //     uint256 depositAmount,
    //     uint256[] calldata _uint256ArgsNFTSupply,
    //     uint256[] calldata _uint256ArgsNFTShares
    // ) external override nonReentrant streamExists(streamId) returns (bool) {
    //     Stream1LibV2.VestingStream1 storage stream = streams1[streamId];
    //     CreateStreamLocalVars memory vars;

    //     require(
    //         block.timestamp < stream.startTime,
    //         "Error: streaming is started"
    //     );

    //     if (
    //         _uint256ArgsNFTSupply.length > 0 &&
    //         _uint256ArgsNFTShares.length == _uint256ArgsNFTSupply.length
    //     ) {
    //         vars.duration = stream.stopTime.sub(stream.startTime);

    //         for (vars.i = 0; vars.i < _uint256ArgsNFTSupply.length; vars.i++) {
    //             vars.nftTotalSupply += _uint256ArgsNFTSupply[vars.i];

    //             vars.ratePerSecond = _uint256ArgsNFTShares[vars.i].div(
    //                 vars.duration
    //             );

    //             vars.streamAmount += _uint256ArgsNFTShares[vars.i].mul(
    //                 _uint256ArgsNFTSupply[vars.i]
    //             );

    //             streams1[streamId].updateStream1(
    //                 ERC721Stream1V2(erc721Address).totalSupply(),
    //                 _uint256ArgsNFTSupply[vars.i],
    //                 _uint256ArgsNFTShares[vars.i],
    //                 vars.ratePerSecond
    //             );
    //         }

    //         require(
    //             depositAmount >= vars.streamAmount,
    //             "Error: Deposit Amount Not Enough"
    //         );

    //         IERC20(stream.tokenAddress).safeTransferFrom(
    //             msg.sender,
    //             address(this),
    //             depositAmount
    //         );
    //         // }

    //         //mint ERC721 to sender
    //         ERC721Stream1V2(erc721Address).mint(
    //             vars.nftTotalSupply,
    //             msg.sender
    //         );

    //         streams1[streamId].deposit += depositAmount;
    //         streams1[streamId].remainingBalance += depositAmount;

    //         // emit UpdateStream(streamId,  vars.nftTotalSupply, tokenShare);

    //         return true;
    //     }
    //     return false;
    // }

    // function depositToken(uint256 streamId, uint256 depositAmount)
    //     external
    //     nonReentrant
    //     streamExists(streamId)
    //     returns (bool)
    // {
    //     require(depositAmount > 0, "Error: depositAmount <= 0");

    //     IERC20(streams1[streamId].tokenAddress).safeTransferFrom(
    //         msg.sender,
    //         address(this),
    //         depositAmount
    //     );

    //     streams1[streamId].depositToken(depositAmount);
    //     return true;
    // }

    /*
     * @notice Withdraws from the contract to the recipient's account.
     * @dev Throws if the id does not point to a valid stream.
     *  Throws if the caller is not the sender or the recipient of the stream.
     *  Throws if the amount exceeds the available balance.
     *  Throws if there is a token transfer failure.
     * @param streamId The id of the stream to withdraw tokens from.
     */
    function withdrawAllFromStream(
        uint256 streamId,
        uint256[] calldata tokenIds
    ) external override nonReentrant streamExists(streamId) returns (bool) {
        Stream1LibV2.VestingStream1 storage stream = streams1[streamId];
        CreateStreamLocalVars memory cvars;
        BalanceOfLocalVars memory bvars;

        require(
            block.timestamp < stream.stopTime,
            "Withdraw Error: streaming is ends"
        );
        if (tokenIds.length <= 0) {
            return false;
        }
        cvars.allAvailableBalance = 0;
        for (bvars.i = 0; bvars.i < tokenIds.length; bvars.i++) {
            bvars.counter = 0;

            if (
                stream.existsTokenId(tokenIds[bvars.i]) &&
                IERC721(stream.erc721Address).ownerOf(tokenIds[bvars.i]) ==
                msg.sender &&
                !effectedTokenIds[block.timestamp].contains(tokenIds[bvars.i])
            ) {
                // console.log(
                //     "contract log withdrawAllFromStream => satisfied nft address: ",
                //     erc721Addresses[bvars.i],
                //     " satisfied tokenId: ",
                //     tokenIds[bvars.j]
                // );
                effectedTokenIds[block.timestamp].add(tokenIds[bvars.i]);
                // console.log(
                //     "contract log withdrawAllFromStream => effectedTokenIds length: ",
                //     effectedTokenIds[block.timestamp].length()
                // );
                bvars.individualBalance = availableBalanceForTokenId(
                    streamId,
                    tokenIds[bvars.i]
                );

                // console.log(
                //     "contract log withdrawAllFromStream => individualBalance: ",
                //     bvars.individualBalance
                // );
                cvars.allAvailableBalance += bvars.individualBalance;
                streams1[streamId].NFTTokenIdWithdrawalAmount[
                    tokenIds[bvars.i]
                ] += bvars.individualBalance;
                // console.log(
                //     "contract log withdrawAllFromStream => NFTTokenIdWithdrawalAmount: ",
                //     streams1[streamId].NFTTokenIdWithdrawalAmount[
                //         tokenIds[bvars.j]
                //     ]
                // );
            }

            delete effectedTokenIds[block.timestamp];
        }

        require(cvars.allAvailableBalance > 0, "withdrawable balance is zero");

        require(
            streams1[streamId].remainingBalance >= cvars.allAvailableBalance,
            "ERROR: Withdraw Amount > Stream Remaining Balance"
        );

        streams1[streamId].remainingBalance = stream.remainingBalance.sub(
            cvars.allAvailableBalance
        );

        cvars.vaultRemainingBalance = IERC20(stream.tokenAddress).balanceOf(
            address(this)
        );
        if (cvars.allAvailableBalance > cvars.vaultRemainingBalance) {
            IERC20(stream.tokenAddress).safeTransfer(
                msg.sender,
                cvars.vaultRemainingBalance
            );
            emit WithdrawAllFromStream(
                streamId,
                msg.sender,
                cvars.vaultRemainingBalance
            );
        } else {
            IERC20(stream.tokenAddress).safeTransfer(
                msg.sender,
                cvars.allAvailableBalance
            );
            emit WithdrawAllFromStream(
                streamId,
                msg.sender,
                cvars.allAvailableBalance
            );
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
        override
        nonReentrant
        streamExists(streamId)
        onlyNFTOwner(tokenId)
        returns (bool)
    {
        Stream1LibV2.VestingStream1 storage stream = streams1[streamId];
        BalanceOfLocalVars memory vars;
        require(
            block.timestamp < stream.stopTime,
            "Withdraw Error: streaming is ends"
        );
        // uint256[2] memory uint256Values = [streamId, tokenId];

        vars.individualBalance = availableBalanceForTokenId(
            streamId,
            tokenId
            // uint256Values
        );
        require(vars.individualBalance > 0, "withdrawable balance is zero");

        require(
            streams1[streamId].remainingBalance >= vars.individualBalance,
            "ERROR: Withdraw Amount > Stream Remaining Balance"
        );
        streams1[streamId].remainingBalance = stream.remainingBalance.sub(
            vars.individualBalance
        );

        // if (streams1[streamId].remainingBalance == 0) delete streams1[streamId];

        uint256 vaultRemainingBalance = IERC20(stream.tokenAddress).balanceOf(
            address(this)
        );

        if (vars.individualBalance > vaultRemainingBalance) {
            streams1[streamId].NFTTokenIdWithdrawalAmount[
                    tokenId
                ] += vaultRemainingBalance;

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
            streams1[streamId].NFTTokenIdWithdrawalAmount[tokenId] += vars
                .individualBalance;

            IERC20(stream.tokenAddress).safeTransfer(
                msg.sender,
                vars.individualBalance
            );

            emit WithdrawFromStreamByTokenId(
                streamId,
                msg.sender,
                tokenId,
                vars.individualBalance
            );
        }

        return true;
    }

    function senderWithdrawFromStream(uint256 streamId)
        external
        nonReentrant
        streamExists(streamId)
        onlySender(streamId)
        returns (bool)
    {
        Stream1LibV2.VestingStream1 storage stream = streams1[streamId];
        require(msg.sender == stream.sender, "Vesting: Permission Deny");
        require(
            block.timestamp >= stream.stopTime,
            "Sender withdraw Error: block timestamp < stoptime"
        );
        uint256 balance = balanceOfSender(streamId);
        require(balance > 0, "Sender Withdrawable Balance Is Zero");

        MathError mathErr;

        require(
            streams1[streamId].remainingBalance >= balance,
            "ERROR: Withdraw Amount > Stream Remaining Balance"
        );

        (mathErr, streams1[streamId].remainingBalance) = subUInt(
            stream.remainingBalance,
            balance
        );

        /**
         * `subUInt` can only return MathError.INTEGER_UNDERFLOW but we know that `remainingBalance` is at least
         * as big as `amount`.
         */
        assert(mathErr == MathError.NO_ERROR);

        // if (streams1[streamId].remainingBalance == 0) delete streams1[streamId];

        uint256 vaultRemainingBalance = IERC20(stream.tokenAddress).balanceOf(
            address(this)
        );
        if (balance > vaultRemainingBalance) {
            IERC20(stream.tokenAddress).safeTransfer(
                msg.sender,
                vaultRemainingBalance
            );
        } else {
            IERC20(stream.tokenAddress).safeTransfer(msg.sender, balance);
        }

        return true;
    }
}
