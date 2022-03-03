// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./shared-contracts/compound/CarefulMath.sol";
import "./interfaces/IVestingV3.sol";
import "./Types.sol";
import "./libraries/StreamLibV3.sol";
import "./libraries/TokenAllocLibV3.sol";
import "./openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./ERC721Stream1V2.sol";
import "./ERC721BatchMint.sol";
import "hardhat/console.sol";

contract StreamV3 is IVestingV3, ReentrancyGuard, CarefulMath {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using StreamLibV3 for StreamLibV3.VestingV3;
    using TokenAllocation for uint256;
    using TokenAllocation for TokenAllocation.TokenIdAllocation;

    using EnumerableSet for EnumerableSet.UintSet;

    /*** Storage Properties ***/

    uint256 public lastAllocation;

    /**
     * @notice Counter for new stream ids.
     */
    uint256 public nextStreamId;

    address public erc721Address;
    /**
     * @notice The stream objects identifiable by their unsigned integer ids.
     */
    mapping(uint256 => StreamLibV3.VestingV3) private streams;
    mapping(uint256 => mapping(address => EnumerableSet.UintSet))
        private effectedTokenIds;

    /*** Modifiers ***/
    modifier onlySender(uint256 streamId) {
        require(
            msg.sender == streams[streamId].sender,
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
        require(streams[streamId].isEntity, "stream does not exist");
        _;
    }

    /*** Contract Logic Starts Here */

    constructor(address _erc721Addr) {
        nextStreamId = 100000;
        erc721Address = _erc721Addr;
    }

    /*** View Functions ***/

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
        sender = streams[streamId].sender;
        deposit = streams[streamId].deposit;
        tokenAddress = streams[streamId].tokenAddress;
        startTime = streams[streamId].startTime;
        stopTime = streams[streamId].stopTime;
        remainingBalance = streams[streamId].remainingBalance;
    }

    function getAllocationInfo(uint256 streamId, uint256 startIndex)
        external
        view
        streamExists(streamId)
        returns (
            uint256 share,
            uint256 size,
            uint256 ratePerSecond
        )
    {
        share = streams[streamId].tokenAllocations[startIndex].share;
        size = streams[streamId].tokenAllocations[startIndex].size;
        ratePerSecond = streams[streamId]
            .tokenAllocations[startIndex]
            .ratePerSecond;
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
        StreamLibV3.VestingV3 storage stream = streams[streamId];
        if (block.timestamp <= stream.startTime) return 0;
        if (block.timestamp < stream.stopTime)
            return block.timestamp - stream.startTime;
        return stream.stopTime - stream.startTime;
    }

    function availableBalanceForTokenId(uint256 streamId, uint256 tokenId)
        public
        view
        streamExists(streamId)
        returns (uint256 balance)
    {
        StreamLibV3.VestingV3 storage stream = streams[streamId];
        BalanceOfLocalVars memory vars;
        uint256 index = tokenId.getAlloctionStart();
        // console.log(
        //     "contract log availableBalanceForTokenId => index of tokenId: ",
        //     tokenId,
        //     " is: ",
        //     index
        // );
        if (!stream.tokenAllocations[index].checkTokenId(tokenId)) {
            return 0;
        }

        uint256 delta = deltaOf(streamId);
        // console.log(
        //     "contract log  availableBalanceForTokenId => delta: ",
        //     delta
        // );
        // console.log(
        //     "Constract Log => tokenIdRatePerSec: ",
        //     stream.tokenIdRatePerSec[tokenId]
        // );
        uint256 totalBalance = delta.mul(
            stream.tokenAllocations[index].getTokenRate(tokenId)
        );
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
        StreamLibV3.VestingV3 storage stream = streams[streamId];

        uint256 index = tokenId.getAlloctionStart();
        if (!stream.tokenAllocations[index].checkTokenId(tokenId)) {
            return 0;
        }
        // console.log(
        //     "Contract Log => stream.tokenIdRatePerSec[tokenId] ",
        //     stream.tokenIdRatePerSec[tokenId]
        // );
        uint256 totalBalance = stream.tokenAllocations[index].share;
        // console.log("Contract Log => totalBalance ", totalBalance);

        uint256 tokenidBalance = totalBalance.sub(
            stream.NFTTokenIdWithdrawalAmount[tokenId]
        );
        // console.log("Contract Log => tokenidBalance ", tokenidBalance);

        return tokenidBalance;
    }

    function checkIfRevoked(uint256 streamId, uint256 tokenId)
        external
        view
        returns (bool)
    {
        return
            streams[streamId]
                .tokenAllocations[tokenId.getAlloctionStart()]
                .checkIfRevoked(tokenId);
    }

    function getAllAllocations(uint256 streamId)
        external
        view
        returns (uint256[] memory)
    {
        return streams[streamId].allocations.values();
    }

    function checkTokenId(uint256 streamId, uint256 tokenId)
        external
        view
        returns (bool)
    {
        return
            streams[streamId]
                .tokenAllocations[tokenId.getAlloctionStart()]
                .checkTokenId(tokenId);
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
        uint256 tokenid;
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
        uint256[3] calldata _uintArgs, //_uintArgs[0] deposit, _uintArgs[1] startTime, _uintArgs[2] stopTime
        address tokenAddress,
        uint256[] calldata _uint256ArgsAllocateAmount,
        uint256[] calldata _uint256ArgsNFTShares
    ) external nonReentrant returns (uint256) {
        // CreateStreamLocalVars memory cvars;
        require(
            _uintArgs[1] >= block.timestamp,
            "start time before block.timestamp"
        );

        require(_uintArgs[2] > _uintArgs[1], "stop time before the start time");

        uint256 streamId = nextStreamId;

        uint256[2] memory uintValues = [
            _uintArgs[1], //startTime
            _uintArgs[2] //stopTime
        ];

        address[3] memory addressValues = [
            msg.sender, //sender
            tokenAddress, //tokenAddress
            erc721Address //erc721Address
        ];

        /* Create and store the stream object. */
        streams[streamId].addStream(uintValues, addressValues, true);

        if (
            _uint256ArgsAllocateAmount.length > 0 ||
            _uint256ArgsNFTShares.length > 0
        ) {
            updasteStream(
                _uintArgs,
                tokenAddress,
                streamId,
                _uint256ArgsAllocateAmount,
                _uint256ArgsNFTShares
            );
        }
        emit CreateStream(
            streamId,
            msg.sender,
            tokenAddress,
            _uintArgs[1],
            _uintArgs[2],
            erc721Address
        );
        /* Increment the next stream id. */
        nextStreamId = nextStreamId.add(uint256(1));

        return streamId;
    }

    function addNewEdition(
        uint256 streamId,
        uint256 deposit,
        uint256[] calldata _uint256ArgsAllocateAmount,
        uint256[] calldata _uint256ArgsNFTShares
    ) external streamExists(streamId) nonReentrant returns (bool) {
        require(
            streams[streamId].startTime > block.timestamp,
            "Stream Has Already Started"
        );
        require(msg.sender == streams[streamId].sender, "only stream sender");

        uint256[3] memory _uintArgs = [
            deposit,
            streams[streamId].startTime, //startTime
            streams[streamId].stopTime //stopTime
        ];

        if (
            _uint256ArgsAllocateAmount.length > 0 ||
            _uint256ArgsNFTShares.length > 0
        ) {
            updasteStream(
                _uintArgs,
                streams[streamId].tokenAddress,
                streamId,
                _uint256ArgsAllocateAmount,
                _uint256ArgsNFTShares
            );
        }

        return true;
    }

    function updasteStream(
        uint256[3] memory _uintArgs,
        address tokenAddress,
        uint256 streamId,
        uint256[] calldata _uint256ArgsAllocateAmount,
        uint256[] calldata _uint256ArgsNFTShares
    ) internal {
        require(
            _uint256ArgsAllocateAmount.length == _uint256ArgsNFTShares.length,
            "ERROR: Mint NFT Amount Not Matach NFT Shares"
        );
        CreateStreamLocalVars memory cvars;
        cvars.duration = _uintArgs[2].sub(_uintArgs[1]);

        for (
            cvars.i = 0;
            cvars.i < _uint256ArgsAllocateAmount.length;
            cvars.i++
        ) {
            cvars.streamAmount += _uint256ArgsAllocateAmount[cvars.i].mul(
                _uint256ArgsNFTShares[cvars.i]
            );

            /* Without this, the rate per second would be zero. */
            require(
                _uint256ArgsNFTShares[cvars.i] >= cvars.duration,
                "nft share smaller than time delta"
            );

            cvars.ratePerSecond = _uint256ArgsNFTShares[cvars.i].div(
                cvars.duration
            );

            streams[streamId].updateStream(
                lastAllocation,
                _uint256ArgsAllocateAmount[cvars.i],
                _uint256ArgsNFTShares[cvars.i],
                cvars.ratePerSecond
            );

            emit AllocateTokenId(
                streamId,
                lastAllocation,
                _uint256ArgsAllocateAmount[cvars.i],
                _uint256ArgsNFTShares[cvars.i]
            );
            lastAllocation += TokenAllocation.getMaxAllocationSize();
        }

        require(
            _uintArgs[0] >= cvars.streamAmount,
            "ERROR: Deposit Amount Insufficient"
        );

        IERC20(tokenAddress).safeTransferFrom(
            msg.sender,
            address(this),
            _uintArgs[0] // deposit
        );

        streams[streamId].depositToken(_uintArgs[0]);
    }

    /*
     * @notice Creates a new stream funded by `msg.sender` and paid towards `recipient`.
     * @dev Throws if the recipient is the zero address, the contract itself or the caller.
     *  Throws if the caller is not stream sender.
     * @param streamId stream ID.
     * @param startIndex tokenID allocation index.
     * @param revokeAmount revoke amount.
     * @return revoke result.
     */
    function revokeStream(
        uint256 streamId,
        uint256 startIndex,
        uint256 revokeAmount
    ) external nonReentrant streamExists(streamId) returns (bool) {
        StreamLibV3.VestingV3 storage stream = streams[streamId];
        require(revokeAmount > 0, "revoke amount must greater than 0");
        require(msg.sender == stream.sender, "only stream sender");

        require(stream.allocations.contains(startIndex), "start index invalid");
        // CreateStreamLocalVars memory cvars;
        BalanceOfLocalVars memory bvars;

        // revoked amount
        bvars.withdrawalAmount = stream
            .tokenAllocations[startIndex]
            .revokedTokenIds
            .length();

        // allocation size of startIndex
        bvars.individualBalance = stream.tokenAllocations[startIndex].size;

        // nft share of startIndex
        bvars.recipientBalance = stream.tokenAllocations[startIndex].share;

        // unminted Token Amount
        bvars.j = ERC721BatchMint(erc721Address).unmintTokenAmount(
            startIndex.add(bvars.withdrawalAmount),
            bvars.individualBalance
        );

        // unrevoked amount
        bvars.senderBalance = bvars.individualBalance.sub(
            bvars.withdrawalAmount
        );

        require(
            bvars.j > 0 && bvars.senderBalance > 0,
            "revokable token amount is zero"
        );

        require(
            revokeAmount <= bvars.j && revokeAmount <= bvars.senderBalance,
            "revoke amount can't greater than revokable size"
        );

        bvars.counter = 0;

        for (
            bvars.i = startIndex.add(bvars.withdrawalAmount);
            bvars.i < startIndex.add(bvars.individualBalance);
            bvars.i++
        ) {
            if (bvars.counter >= revokeAmount) {
                break;
            }

            // token i hasn't been minted && unrevoked
            if (
                !ERC721BatchMint(erc721Address).exists(bvars.i) &&
                !stream.tokenAllocations[startIndex].checkIfRevoked(bvars.i)
            ) {
                stream.tokenAllocations[startIndex].revokeToken(bvars.i); //revoke token i
                bvars.counter += 1;
            }
        }

        require(bvars.counter > 0, "revokable token amount is zero");

        require(
            bvars.counter == revokeAmount,
            "revoke amount exceeds revokable amount"
        );

        // require(
        //     stream.remainingBalance >=
        //         bvars.counter.mul(bvars.recipientBalance) &&
        //         stream.deposit >= bvars.counter.mul(bvars.recipientBalance),
        //     "Revoke Error: Insufficient Balance"
        // );
        streams[streamId].deposit -= bvars.counter.mul(bvars.recipientBalance);
        streams[streamId].remainingBalance -= bvars.counter.mul(
            bvars.recipientBalance
        );

        IERC20(stream.tokenAddress).safeTransfer(
            msg.sender,
            bvars.counter.mul(bvars.recipientBalance)
        );

        emit RevokeAllocation(streamId, startIndex, bvars.counter);

        return true;
    }

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
        StreamLibV3.VestingV3 storage stream = streams[streamId];
        CreateStreamLocalVars memory cvars;
        BalanceOfLocalVars memory bvars;
        // require(
        //     block.timestamp < stream.stopTime,
        //     "Withdraw Error: streaming is ends"
        // );
        if (tokenIds.length <= 0) {
            return false;
        }

        cvars.allAvailableBalance = 0;
        for (bvars.i = 0; bvars.i < tokenIds.length; bvars.i++) {
            cvars.tokenid = tokenIds[bvars.i];
            if (
                stream
                    .tokenAllocations[cvars.tokenid.getAlloctionStart()]
                    .checkTokenId(cvars.tokenid) &&
                IERC721(stream.erc721Address).ownerOf(cvars.tokenid) ==
                msg.sender &&
                !effectedTokenIds[block.timestamp][msg.sender].contains(
                    cvars.tokenid
                )
            ) {
                effectedTokenIds[block.timestamp][msg.sender].add(
                    cvars.tokenid
                );

                bvars.individualBalance = availableBalanceForTokenId(
                    streamId,
                    cvars.tokenid
                );

                cvars.allAvailableBalance += bvars.individualBalance;
                streams[streamId].NFTTokenIdWithdrawalAmount[
                    cvars.tokenid
                ] += bvars.individualBalance;
                {
                    emit WithdrawFromStreamByTokenId(
                        streamId,
                        msg.sender,
                        cvars.tokenid,
                        bvars.individualBalance,
                        stream
                            .tokenAllocations[cvars.tokenid.getAlloctionStart()]
                            .share
                            .sub(
                                streams[streamId].NFTTokenIdWithdrawalAmount[
                                    cvars.tokenid
                                ]
                            )
                    );
                }
            }

            delete effectedTokenIds[block.timestamp][msg.sender];
        }

        require(cvars.allAvailableBalance > 0, "withdrawable balance is zero");

        require(
            streams[streamId].remainingBalance >= cvars.allAvailableBalance,
            "ERROR: Withdraw Amount > Stream Remaining Balance"
        );

        streams[streamId].remainingBalance = stream.remainingBalance.sub(
            cvars.allAvailableBalance
        );

        IERC20(stream.tokenAddress).safeTransfer(
            msg.sender,
            cvars.allAvailableBalance
        );

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
        StreamLibV3.VestingV3 storage stream = streams[streamId];
        BalanceOfLocalVars memory vars;
        // require(
        //     block.timestamp < stream.stopTime,
        //     "Withdraw Error: streaming is ends"
        // );

        vars.individualBalance = availableBalanceForTokenId(streamId, tokenId);
        require(vars.individualBalance > 0, "withdrawable balance is zero");

        require(
            streams[streamId].remainingBalance >= vars.individualBalance,
            "ERROR: Withdraw Amount > Stream Remaining Balance"
        );
        streams[streamId].remainingBalance = stream.remainingBalance.sub(
            vars.individualBalance
        );

        streams[streamId].NFTTokenIdWithdrawalAmount[tokenId] += vars
            .individualBalance;

        IERC20(stream.tokenAddress).safeTransfer(
            msg.sender,
            vars.individualBalance
        );

        emit WithdrawFromStreamByTokenId(
            streamId,
            msg.sender,
            tokenId,
            vars.individualBalance,
            streams[streamId]
                .tokenAllocations[tokenId.getAlloctionStart()]
                .share
                .sub(streams[streamId].NFTTokenIdWithdrawalAmount[tokenId])
        );

        return true;
    }

    // function senderWithdrawFromStream(uint256 streamId)
    //     external
    //     override
    //     nonReentrant
    //     streamExists(streamId)
    //     onlySender(streamId)
    //     returns (bool)
    // {
    //     StreamLibV3.VestingV3 storage stream = streams[streamId];
    //     require(msg.sender == stream.sender, "only stream sender");
    //     require(
    //         block.timestamp >= stream.stopTime,
    //         "Sender withdraw Error: block timestamp < stoptime"
    //     );

    //     require(
    //         streams[streamId].remainingBalance > 0,
    //         "ERROR: Stream Remaining Balance InSufficient"
    //     );

    //     // if (streams1[streamId].remainingBalance == 0) delete streams1[streamId];

    //     uint256 vaultRemainingBalance = IERC20(stream.tokenAddress).balanceOf(
    //         address(this)
    //     );
    //     if (streams[streamId].remainingBalance > vaultRemainingBalance) {
    //         IERC20(stream.tokenAddress).safeTransfer(
    //             msg.sender,
    //             vaultRemainingBalance
    //         );
    //         emit SenderWithdraw(streamId, vaultRemainingBalance);
    //     } else {
    //         IERC20(stream.tokenAddress).safeTransfer(
    //             msg.sender,
    //             streams[streamId].remainingBalance
    //         );
    //         emit SenderWithdraw(streamId, streams[streamId].remainingBalance);
    //     }

    //     streams[streamId].remainingBalance = 0;

    //     return true;
    // }
}
