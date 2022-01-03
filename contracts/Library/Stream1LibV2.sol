// pragma solidity =0.5.17;
pragma solidity ^0.8.0;
import "../openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../openzeppelin/contracts/utils/math/SafeMath.sol";
import "hardhat/console.sol";

library Stream1LibV2 {
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using SafeMath for uint256;

    struct VestingStream1 {
        uint256 deposit;
        uint256 remainingBalance;
        uint256 startTime;
        uint256 stopTime;
        address sender;
        address tokenAddress;
        address erc721Address;
        bool isEntity;
        EnumerableSet.UintSet tokenIds;
        mapping(uint256 => uint256) tokenIdShare; // tokenId => shares
        mapping(uint256 => uint256) tokenIdRatePerSec; // tokenId=>ratePerSecond
        mapping(uint256 => uint256) NFTTokenIdWithdrawalAmount; // tokenId => withdrawal amount
    }

    function addStream1(
        VestingStream1 storage stream1,
        uint256[2] memory _uintArgs,
        address[3] memory _addressArgs, // address sender,address tokenAddress, address ERC721
        bool isEntity
    ) internal returns (bool) {
        stream1.deposit = 0;
        stream1.remainingBalance = 0;
        stream1.startTime = _uintArgs[0];
        stream1.stopTime = _uintArgs[1];
        stream1.sender = _addressArgs[0];
        stream1.tokenAddress = _addressArgs[1];
        stream1.erc721Address = _addressArgs[2];
        stream1.isEntity = isEntity;

        // for (uint256 i = 0; i < _uintArgs[6]; i++) {
        //     stream1.tokenIds.add(i);
        //     stream1.tokenIdShare[i] = _uintArgs[5];
        //     stream1.tokenIdRatePerSec[i] = _uintArgs[1];
        // }

        return true;
    }

    function depositToken(VestingStream1 storage stream1, uint256 depositAmount)
        internal
        returns (bool)
    {
        stream1.deposit += depositAmount;
        stream1.remainingBalance += depositAmount;

        return true;
    }

    function updateStream1(
        VestingStream1 storage stream1,
        // uint256 additionDeposit,
        uint256 startIndex,
        uint256 preMintAmount,
        uint256 tokenIdShare,
        uint256 ratePerSecond
    ) internal returns (bool) {
        // require(
        //     additionDeposit >= preMintAmount.mul(tokenIdShare),
        //     "ERROR: Deposit Amount Insufficient"
        // );
        // console.log("Constract Log => startIndex: ", startIndex);
        // console.log("Constract Log => preMintAmount: ", preMintAmount);

        for (uint256 i = startIndex; i < startIndex.add(preMintAmount); i++) {
            // console.log("Contract Log => tokenId", i);
            require(stream1.tokenIds.add(i), "Error: Add TokenId Failed");
            // console.log(
            //     "Contract Log => tokenIds.length",
            //     stream1.tokenIds.length()
            // );
            stream1.tokenIdShare[i] = tokenIdShare;
            stream1.tokenIdRatePerSec[i] = ratePerSecond;
        }
        // stream1.deposit += additionDeposit;
        // stream1.remainingBalance += additionDeposit;

        return true;
    }

    function tokenIdValues(VestingStream1 storage stream1)
        external
        view
        returns (uint256[] memory)
    {
        return stream1.tokenIds.values();
    }

    function existsTokenId(VestingStream1 storage stream1, uint256 tokenId)
        external
        view
        returns (bool)
    {
        return stream1.tokenIds.contains(tokenId);
    }
}
