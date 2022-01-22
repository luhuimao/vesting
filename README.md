# Basic Sample Hardhat Project

This project demonstrates a basic Hardhat use case. It comes with a sample contract, a test for that contract, a sample script that deploys that contract, and an example of a task implementation, which simply lists the available accounts.

Try running some of the following tasks:

```shell
npx hardhat accounts
npx hardhat compile
npx hardhat clean
npx hardhat test
npx hardhat node
node scripts/sample-script.js
npx hardhat help
```
# vesting

## create a new stream
```
    instanceStreamV3.createStream(
        [
            hre.ethers.utils.parseEther("200000"),
            startTime,
            stopTime
        ],
        instanceTESTERC20.address,
        [10, 20, 30],
        [
            hre.ethers.utils.parseEther("100"),
            hre.ethers.utils.parseEther("200"),
            hre.ethers.utils.parseEther("300")
        ]
    );

    parameters:
    int[3](int[0]: deposit token amount; int[1]: stream start timestamp; int[2]: stream stop timestamp),
    stream token contract address,
    editions array: each edition can't exceed 200,
    token per edition array: length must equal to editions array
    Note:
    token deposit amount must >= sum(edition * token per edition)
```
## get available balance by tokenId
```
instanceStreamV3.availableBalanceForTokenId(int streamId, int tokenId);
```
    
## get remaining balance by tokenId
```
instanceStreamV3.remainingBalanceByTokenId(int streamId, int tokenId);
```
## withdraw by tokenId
```
instanceStreamV3.withdrawFromStreamByTokenId(int streamId, int tokenId);
```
## withdraw all
```
instanceStreamV3.withdrawAllFromStream(int streamId, int[] tokenIds);
```
## sender Withdraw
```
instanceStreamV3.senderWithdrawFromStream(int streamId);
```

## revoke
```
instanceStreamV3.revokeStream(int streamId, int startIndex, int revokeAmount)
```

## check tokenId if included
```
instanceStreamV3.checkTokenId(int streamId, int tokenId)

```
return true if included in stream of streamId

## StreamV3 deployed Address:
Rinkeby 0x53E717AEEfCddF7013DFD9B63385b970836a85f9