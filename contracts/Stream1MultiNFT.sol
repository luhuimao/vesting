// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./shared-contracts/compound/CarefulMath.sol";
import "./interfaces/IVesting1.sol";
import "./Types.sol";
import "./libraries/Stream1Lib.sol";
import "./ERC721.sol";
import "./test/testNFT.sol";
import "./openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "hardhat/console.sol";

/**
 * @title Vesting
 * @author Benjamin
 * @notice Money streaming.
 */
contract Stream1MultiNFT is ReentrancyGuard, CarefulMath {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using Stream1Lib for Stream1Lib.VestingStream1;
    using EnumerableSet for EnumerableSet.UintSet;

    /*** Storage Properties ***/

    /**
     * @notice Counter for new stream ids.
     */
    uint256 public nextStreamId;
    /**
     * @notice The stream objects identifiable by their unsigned integer ids.
     */

    mapping(uint256 => Stream1Lib.VestingStream1) private streams1;
    mapping(address => EnumerableSet.UintSet) private effectedTokenIds;
    /*** Modifiers ***/

    /**
     * @dev Throws if the caller is not the sender of the recipient of the stream.
     */
    // modifier onlySenderOrRecipient(
    //     uint256 streamId,
    //     address nftaddr,
    //     uint256 tokenid
    // ) {
    //     require(
    //         msg.sender == streams1[streamId].sender ||
    //             (streams1[streamId].existsNft(nftaddr) &&
    //                 streams1[streamId].existsTokenId(nftaddr, tokenid) &&
    //                 IERC721(nftaddr).ownerOf(tokenid) == msg.sender),
    //         "caller is not the sender or the recipient of the stream"
    //     );
    //     _;
    // }

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
    modifier onlyNFTOwner(address nftAddress, uint256 tokenId) {
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
        require(streams1[streamId].isEntity, "stream does not exist");
        _;
    }

    event CreateStream1(
        uint256 indexed streamId,
        address indexed sender
        // uint256 deposit,
        // address tokenAddress,
        // uint256 startTime,
        // uint256 stopTime,
        // address[] erc721Addresses
    );

    event WithdrawAllFromStream(
        uint256 indexed streamId,
        address indexed sender,
        uint256 amount
    );

    event WithdrawFromStreamByTokenId(
        uint256 indexed streamId,
        address indexed sender,
        uint256 indexed tokenId,
        uint256 amount
    );

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
        streamExists(streamId)
        returns (
            address sender,
            uint256 deposit,
            address tokenAddress,
            uint256 startTime,
            uint256 stopTime,
            uint256 remainingBalance,
            uint256 ratePerSecond
        )
    {
        sender = streams1[streamId].sender;
        deposit = streams1[streamId].deposit;
        tokenAddress = streams1[streamId].tokenAddress;
        startTime = streams1[streamId].startTime;
        stopTime = streams1[streamId].stopTime;
        remainingBalance = streams1[streamId].remainingBalance;
        ratePerSecond = streams1[streamId].ratePerSecond;
    }

    function getStreamSupportedNFT(uint256 streamId)
        external
        view
        streamExists(streamId)
        returns (address[] memory)
    {
        return streams1[streamId].nftAddressValues();
    }

    function getStreamSupportedTokenIds(uint256 streamId, address nftAddress)
        external
        view
        streamExists(streamId)
        returns (uint256[] memory)
    {
        return streams1[streamId].tokenIdValues(nftAddress);
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
        Stream1Lib.VestingStream1 storage stream = streams1[streamId];
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
        address[] memory nftAddresses,
        uint256[] memory tokenIdIndex,
        uint256[] memory tokenIds
    ) public view streamExists(streamId) returns (uint256 balance) {
        Stream1Lib.VestingStream1 storage stream = streams1[streamId];
        BalanceOfLocalVars memory vars;
        require(
            nftAddresses.length > 0 &&
                tokenIdIndex.length > 0 &&
                nftAddresses.length == tokenIdIndex.length
        );
        vars.recipientBalance = 0;
        vars.counter = 0;
        for (vars.i = 0; vars.i < nftAddresses.length; vars.i++) {
            for (
                vars.j = vars.counter;
                vars.j < tokenIdIndex[vars.i] + vars.counter;
                vars.j++
            ) {
                if (
                    stream.existsNft(nftAddresses[vars.i]) &&
                    stream.existsTokenId(
                        nftAddresses[vars.i],
                        tokenIds[vars.j]
                    ) &&
                    IERC721(nftAddresses[vars.i]).ownerOf(tokenIds[vars.j]) ==
                    who
                ) {
                    vars.individualBalance = availableBalanceForTokenId(
                        streamId,
                        nftAddresses[vars.i],
                        tokenIds[vars.j]
                    );
                    // console.log(
                    //     "contract log => vars.individualBalance: ",
                    //     vars.individualBalance
                    // );
                    vars.recipientBalance += vars.individualBalance;
                }
            }
            vars.counter += tokenIdIndex[vars.i];
        }
        return vars.recipientBalance;
    }

    function availableBalanceForTokenId(
        uint256 streamId,
        address nftAddress,
        uint256 tokenId
    ) public view streamExists(streamId) returns (uint256 balance) {
        Stream1Lib.VestingStream1 storage stream = streams1[streamId];
        BalanceOfLocalVars memory vars;

        if (
            !stream.existsNft(nftAddress) ||
            !stream.existsTokenId(nftAddress, tokenId)
        ) {
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

        uint256 totalBalance = delta.mul(stream.ratePerSecond);
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
            stream.NFTTokenIdWithdrawalAmount[nftAddress][tokenId]
        );

        return vars.recipientBalance;
    }

    function remainingBalanceByTokenId(
        uint256 streamId,
        address nftAddress,
        uint256 tokenId
    ) public view returns (uint256) {
        Stream1Lib.VestingStream1 storage stream = streams1[streamId];

        if (
            !stream.existsNft(nftAddress) ||
            !stream.existsTokenId(nftAddress, tokenId)
        ) {
            return 0;
        }
        uint256 streamDuration = stream.stopTime - stream.startTime;

        uint256 totalBalance = streamDuration.mul(stream.ratePerSecond);
        uint256 tokenidBalance = totalBalance.sub(
            stream.NFTTokenIdWithdrawalAmount[nftAddress][tokenId]
        );

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

    /*** Public Effects & Interactions Functions ***/

    struct CreateStreamLocalVars {
        uint256 duration;
        uint256 ratePerSecond;
        uint256 totalDuration;
        uint256 nftTotalSupply;
        uint256 vaultRemainingBalance;
        uint256 allAvailableBalance;
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
        uint256[3] calldata _uintArgs, //_uintArgs[0] deposit, _uintArgs[1] startTime, _uintArgs[2] stopTime,
        address tokenAddress,
        address[] calldata erc721Addresses,
        uint256[] calldata tokenIdIndex,
        uint256[] calldata tokenIds
    ) external returns (uint256) {
        require(_uintArgs[0] > 0, "deposit is zero");

        require(
            _uintArgs[1] >= block.timestamp,
            "start time before block.timestamp"
        );
        // require(stopTime > startTime, "stop time before the start time");
        require(_uintArgs[2] > _uintArgs[1], "stop time before the start time");

        CreateStreamLocalVars memory vars;

        vars.duration = _uintArgs[2].sub(_uintArgs[1]);

        vars.nftTotalSupply = 0;

        for (uint256 i = 0; i < tokenIdIndex.length; i++) {
            vars.nftTotalSupply += tokenIdIndex[i];
        }

        vars.totalDuration = vars.duration.mul(vars.nftTotalSupply);

        /* Without this, the rate per second would be zero. */
        require(
            _uintArgs[0] >= vars.totalDuration,
            "deposit smaller than time delta"
        );

        vars.ratePerSecond = _uintArgs[0].div(vars.totalDuration);

        /* Create and store the stream object. */
        uint256 streamId = nextStreamId;

        uint256[6] memory uintValues = [
            _uintArgs[0], //deposit
            vars.ratePerSecond, //ratePerSecond
            _uintArgs[0], //remainingBalance
            _uintArgs[1], //startTime
            _uintArgs[2], //stopTime
            vars.nftTotalSupply //nftTotalAmount
        ];

        address[2] memory addressValues = [
            msg.sender, //sender
            tokenAddress //tokenAddress
        ];

        streams1[streamId].addStream1(
            uintValues,
            addressValues,
            true,
            erc721Addresses,
            tokenIdIndex,
            tokenIds
        );
        /* Increment the next stream id. */
        nextStreamId = nextStreamId.add(uint256(1));

        IERC20(tokenAddress).safeTransferFrom(
            msg.sender,
            address(this),
            _uintArgs[0] // deposit
        );

        emit CreateStream1(
            streamId,
            msg.sender
            // _uintArgs[0], // deposit,
            // tokenAddress,
            // _uintArgs[1], // startTime,
            // _uintArgs[2], // stopTime,
            // erc721Addresses
        );
        return streamId;
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
        address[] calldata erc721Addresses,
        uint256[] calldata tokenIdIndex,
        uint256[] calldata tokenIds
    ) external nonReentrant streamExists(streamId) returns (bool) {
        Stream1Lib.VestingStream1 storage stream = streams1[streamId];
        CreateStreamLocalVars memory cvars;
        BalanceOfLocalVars memory bvars;

        require(
            block.timestamp < stream.stopTime,
            "Withdraw Error: streaming is ends"
        );
        cvars.allAvailableBalance = 0;
        for (bvars.i = 0; bvars.i < erc721Addresses.length; bvars.i++) {
            bvars.counter = 0;
            for (
                bvars.j = bvars.counter;
                bvars.j < tokenIdIndex[bvars.i] + bvars.counter;
                bvars.j++
            ) {
                if (
                    stream.existsNft(erc721Addresses[bvars.i]) &&
                    stream.existsTokenId(
                        erc721Addresses[bvars.i],
                        tokenIds[bvars.j]
                    ) &&
                    IERC721(erc721Addresses[bvars.i]).ownerOf(
                        tokenIds[bvars.j]
                    ) ==
                    msg.sender &&
                    !effectedTokenIds[erc721Addresses[bvars.i]].contains(
                        tokenIds[bvars.j]
                    )
                ) {
                    // console.log(
                    //     "contract log withdrawAllFromStream => satisfied nft address: ",
                    //     erc721Addresses[bvars.i],
                    //     " satisfied tokenId: ",
                    //     tokenIds[bvars.j]
                    // );
                    effectedTokenIds[erc721Addresses[bvars.i]].add(
                        tokenIds[bvars.j]
                    );
                    console.log(
                        "contract log withdrawAllFromStream => effectedTokenIds length: ",
                        effectedTokenIds[erc721Addresses[bvars.i]].length()
                    );
                    // bvars.individualBalance = availableBalanceForTokenId(
                    //     streamId,
                    //     erc721Addresses[bvars.i],
                    //     tokenIds[bvars.j]
                    // );

                    withdrawFromStreamByTokenId(
                        streamId,
                        erc721Addresses[bvars.i],
                        tokenIds[bvars.j]
                    );
                    // console.log(
                    //     "contract log withdrawAllFromStream => individualBalance: ",
                    //     bvars.individualBalance
                    // );
                    // cvars.allAvailableBalance += bvars.individualBalance;
                    // streams1[streamId].NFTTokenIdWithdrawalAmount[
                    //     erc721Addresses[bvars.i]
                    // ][tokenIds[bvars.j]] += bvars.individualBalance;
                    // console.log(
                    //     "contract log withdrawAllFromStream => NFTTokenIdWithdrawalAmount: ",
                    //     streams1[streamId].NFTTokenIdWithdrawalAmount[
                    //         erc721Addresses[bvars.i]
                    //     ][tokenIds[bvars.j]]
                    // );
                }
            }
            delete effectedTokenIds[erc721Addresses[bvars.i]];
            bvars.counter += tokenIdIndex[bvars.i];
        }
        // require(cvars.allAvailableBalance > 0, "withdrawable balance is zero");

        // require(
        //     streams1[streamId].remainingBalance >= cvars.allAvailableBalance,
        //     "ERROR: Withdraw Amount > Stream Remaining Balance"
        // );

        // streams1[streamId].remainingBalance = stream.remainingBalance.sub(
        //     cvars.allAvailableBalance
        // );

        // if (streams1[streamId].remainingBalance == 0) delete streams1[streamId];

        // cvars.vaultRemainingBalance = IERC20(stream.tokenAddress).balanceOf(
        //     address(this)
        // );
        // if (cvars.allAvailableBalance > cvars.vaultRemainingBalance) {
        //     IERC20(stream.tokenAddress).safeTransfer(
        //         msg.sender,
        //         cvars.vaultRemainingBalance
        //     );
        //     emit WithdrawAllFromStream(
        //         streamId,
        //         msg.sender,
        //         cvars.vaultRemainingBalance
        //     );
        // } else {
        //     IERC20(stream.tokenAddress).safeTransfer(
        //         msg.sender,
        //         cvars.allAvailableBalance
        //     );
        //     emit WithdrawAllFromStream(
        //         streamId,
        //         msg.sender,
        //         cvars.allAvailableBalance
        //     );
        // }

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
    function withdrawFromStreamByTokenId(
        uint256 streamId,
        address nftAddress,
        uint256 tokenId
    )
        public
        nonReentrant
        streamExists(streamId)
        onlyNFTOwner(nftAddress, tokenId)
        returns (bool)
    {
        Stream1Lib.VestingStream1 storage stream = streams1[streamId];
        BalanceOfLocalVars memory vars;
        require(
            block.timestamp < stream.stopTime,
            "Withdraw Error: streaming is ends"
        );
        // uint256[2] memory uint256Values = [streamId, tokenId];

        vars.individualBalance = availableBalanceForTokenId(
            streamId,
            nftAddress,
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
            streams1[streamId].NFTTokenIdWithdrawalAmount[nftAddress][
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
            streams1[streamId].NFTTokenIdWithdrawalAmount[nftAddress][
                tokenId
            ] += vars.individualBalance;

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
        Stream1Lib.VestingStream1 storage stream = streams1[streamId];
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
