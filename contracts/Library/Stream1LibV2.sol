// pragma solidity =0.5.17;
pragma solidity ^0.8.0;
import "../openzeppelin/contracts/utils/structs/EnumerableSet.sol";

library Stream1LibV2 {
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.Bytes32Set;

    struct VestingStream1 {
        uint256 deposit;
        uint256 ratePerSecond;
        uint256 remainingBalance;
        uint256 startTime;
        uint256 stopTime;
        address sender;
        address tokenAddress;
        bool isEntity;
        // uint256 nftTotalSupply;
        EnumerableSet.Bytes32Set nftNameSet;
        EnumerableSet.AddressSet nftAddresses;

        mapping(bytes32 => mapping(uint256 => uint256)) perNFTSharesByName; //nftName=>nftTotalSupply=>Share
        mapping(address => mapping(uint256 => uint256)) perNFTShares; //erc721Address=>nftTotalSupply=>Share
        // mapping(address => EnumerableSet.UintSet) nftTokenIds;
        mapping(address => mapping(uint256 => uint256)) NFTTokenIdWithdrawalAmount;
    }

    function addStream1(
        VestingStream1 storage stream1,
        uint256[6] memory _uintArgs,
        address[2] memory _addressArgs, // address sender,address tokenAddress,
        bool isEntity,
        address[] memory erc721Addresses,
        uint256[] memory tokenIdIndex,
        uint256[] memory tokenIds
    ) internal returns (bool) {
        stream1.deposit = _uintArgs[0];
        stream1.ratePerSecond = _uintArgs[1];
        stream1.remainingBalance = _uintArgs[2];
        stream1.startTime = _uintArgs[3];
        stream1.stopTime = _uintArgs[4];
        stream1.nftTotalSupply = _uintArgs[5];
        stream1.sender = _addressArgs[0];
        stream1.tokenAddress = _addressArgs[1];
        stream1.isEntity = isEntity;

        uint256 nftTotalSupply = 0;

        for (uint256 i = 0; i < tokenIdIndex.length; i++) {
            for (
                uint256 j = nftTotalSupply;
                j < tokenIdIndex[i] + nftTotalSupply;
                j++
            ) {
                stream1.nftTokenIds[erc721Addresses[i]].add(tokenIds[j]);
                stream1.nftAddresses.add(erc721Addresses[i]);
            }
            nftTotalSupply += tokenIdIndex[i];
        }

        return true;
    }

    function nftAddressValues(VestingStream1 storage stream1)
        external
        view
        returns (address[] memory)
    {
        return stream1.nftAddresses.values();
    }

    function tokenIdValues(VestingStream1 storage stream1, address nftAddress)
        external
        view
        returns (uint256[] memory)
    {
        return stream1.nftTokenIds[nftAddress].values();
    }

    function existsNft(VestingStream1 storage stream1, address nftAddr)
        external
        view
        returns (bool)
    {
        return stream1.nftAddresses.contains(nftAddr);
    }

    function existsTokenId(
        VestingStream1 storage stream1,
        address nftAddr,
        uint256 tokenId
    ) external view returns (bool) {
        return stream1.nftTokenIds[nftAddr].contains(tokenId);
    }
}
