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
instanceStreamV3.availableBalanceForTokenId(int steramId, int tokenId);
```
    
## get remaining balance by tokenId
```
instanceStreamV3.remainingBalanceByTokenId(int steramId, int tokenId);
```
## withdraw by tokenId
```
instanceStreamV3.withdrawFromStreamByTokenId(int steramId, int tokenId);
```
## withdraw all
```
instanceStreamV3.withdrawAllFromStream(int steramId, int[] tokenIds);
```
## sender Withdraw
```
instanceStreamV3.senderWithdrawFromStream(int steramId);
```


## StreamV3 deployed Address:
Rinkeby 0x8b201D78c8C2d1b06e9144CA73baBff013AfEcE0