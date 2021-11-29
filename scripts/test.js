const Web3 = require('web3')
const ethers = require("ethers");

vesting2ContractABI = [
    {
        "inputs": [],
        "stateMutability": "nonpayable",
        "type": "constructor"
    },
    {
        "anonymous": false,
        "inputs": [
            {
                "indexed": true,
                "internalType": "uint256",
                "name": "streamId",
                "type": "uint256"
            },
            {
                "indexed": true,
                "internalType": "address",
                "name": "sender",
                "type": "address"
            },
            {
                "indexed": false,
                "internalType": "uint256",
                "name": "deposit",
                "type": "uint256"
            },
            {
                "indexed": false,
                "internalType": "address",
                "name": "tokenAddress",
                "type": "address"
            },
            {
                "indexed": false,
                "internalType": "uint256",
                "name": "startTime",
                "type": "uint256"
            },
            {
                "indexed": false,
                "internalType": "uint256",
                "name": "stopTime",
                "type": "uint256"
            },
            {
                "indexed": false,
                "internalType": "address",
                "name": "erc721Address",
                "type": "address"
            }
        ],
        "name": "CreateStream2",
        "type": "event"
    },
    {
        "anonymous": false,
        "inputs": [
            {
                "indexed": true,
                "internalType": "uint256",
                "name": "stream2Id",
                "type": "uint256"
            },
            {
                "indexed": true,
                "internalType": "address",
                "name": "recipient",
                "type": "address"
            },
            {
                "indexed": false,
                "internalType": "uint256",
                "name": "amount",
                "type": "uint256"
            }
        ],
        "name": "WithdrawFromStream2",
        "type": "event"
    },
    {
        "inputs": [
            {
                "internalType": "uint256",
                "name": "stream2Id",
                "type": "uint256"
            },
            {
                "internalType": "address",
                "name": "who",
                "type": "address"
            }
        ],
        "name": "balanceOf2",
        "outputs": [
            {
                "internalType": "uint256",
                "name": "balance",
                "type": "uint256"
            }
        ],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [
            {
                "internalType": "uint256",
                "name": "stream2Id",
                "type": "uint256"
            }
        ],
        "name": "balanceOfSender2",
        "outputs": [
            {
                "internalType": "uint256",
                "name": "balance",
                "type": "uint256"
            }
        ],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [
            {
                "internalType": "uint256",
                "name": "deposit",
                "type": "uint256"
            },
            {
                "internalType": "address",
                "name": "tokenAddress",
                "type": "address"
            },
            {
                "internalType": "uint256",
                "name": "startTime",
                "type": "uint256"
            },
            {
                "internalType": "uint256",
                "name": "stopTime",
                "type": "uint256"
            },
            {
                "internalType": "address",
                "name": "erc721Address",
                "type": "address"
            },
            {
                "components": [
                    {
                        "internalType": "uint256",
                        "name": "tokenid",
                        "type": "uint256"
                    },
                    {
                        "internalType": "uint256",
                        "name": "share",
                        "type": "uint256"
                    }
                ],
                "internalType": "struct VestingTypes.NFTShares[]",
                "name": "nftShares",
                "type": "tuple[]"
            }
        ],
        "name": "createStream2",
        "outputs": [
            {
                "internalType": "uint256",
                "name": "",
                "type": "uint256"
            }
        ],
        "stateMutability": "nonpayable",
        "type": "function"
    },
    {
        "inputs": [
            {
                "internalType": "uint256",
                "name": "stream2Id",
                "type": "uint256"
            }
        ],
        "name": "deltaOf2",
        "outputs": [
            {
                "internalType": "uint256",
                "name": "delta",
                "type": "uint256"
            }
        ],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [
            {
                "internalType": "uint256",
                "name": "stream2Id",
                "type": "uint256"
            }
        ],
        "name": "getStream2",
        "outputs": [
            {
                "internalType": "address",
                "name": "sender",
                "type": "address"
            },
            {
                "internalType": "uint256",
                "name": "deposit",
                "type": "uint256"
            },
            {
                "internalType": "address",
                "name": "tokenAddress",
                "type": "address"
            },
            {
                "internalType": "uint256",
                "name": "startTime",
                "type": "uint256"
            },
            {
                "internalType": "uint256",
                "name": "stopTime",
                "type": "uint256"
            },
            {
                "internalType": "uint256",
                "name": "remainingBalance",
                "type": "uint256"
            },
            {
                "internalType": "uint256",
                "name": "ratePerSecond",
                "type": "uint256"
            },
            {
                "internalType": "address",
                "name": "erc721Address",
                "type": "address"
            }
        ],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [],
        "name": "nextStream2Id",
        "outputs": [
            {
                "internalType": "uint256",
                "name": "",
                "type": "uint256"
            }
        ],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [
            {
                "internalType": "uint256",
                "name": "stream2Id",
                "type": "uint256"
            }
        ],
        "name": "senderWithdrawFromStream2",
        "outputs": [
            {
                "internalType": "bool",
                "name": "",
                "type": "bool"
            }
        ],
        "stateMutability": "nonpayable",
        "type": "function"
    },
    {
        "inputs": [
            {
                "internalType": "uint256",
                "name": "stream2Id",
                "type": "uint256"
            }
        ],
        "name": "withdrawFromStream2",
        "outputs": [
            {
                "internalType": "bool",
                "name": "",
                "type": "bool"
            }
        ],
        "stateMutability": "nonpayable",
        "type": "function"
    }
];
vesting2ContractAddressRINKEBY = "0x2880c5Cfb7BB84784BD465CC850bd2bf701cC66F";
web3 = new Web3("https://rinkeby.infura.io/v3/04dd3493f83c48de9735b4b29f108b84");
const v2Contract = new web3.eth.Contract(vesting2ContractABI, vesting2ContractAddressRINKEBY);
(async () => {

    const blockNumber = await web3.eth.getBlockNumber();
    const blockHash = await web3.eth.getBlock(await web3.eth.getBlockNumber())
        .hash;
    const blocktimestamp = (await web3.eth.getBlock(await web3.eth.getBlockNumber()))
        .timestamp
    // var blockNumber = await web3.eth.blockNumber;
    console.log("blocktimestamp", blocktimestamp);
    // let blocktimestamp = await web3.eth.getBlock(blockNumber).timestamp;
    console.log(`current timestamp: ${blocktimestamp.toString()}`);
    const startTime = blocktimestamp + 100;
    const stopTime = startTime + 2000;
    const approveEncodedABI = v2Contract.methods.createStream2(
        10000,
        "0x524A71eAaFC549Cbdf2013A9f9A7A356a9E54372",
        startTime,
        stopTime,
        "0x9Db201a9eA5b37Ce49480304fd34C42B3EBc10E3",
        [
            { tokenid: 0, share: 1000 },
            { tokenid: 1, share: 2000 },
            { tokenid: 2, share: 3000 },
            { tokenid: 3, share: 4000 },
            { tokenid: 4, share: 5000 },
            { tokenid: 5, share: 6000 },
            { tokenid: 6, share: 7000 },
            { tokenid: 7, share: 8000 },
            { tokenid: 8, share: 9000 },
            { tokenid: 9, share: 10000 },
            { tokenid: 10, share: 6000 },
            { tokenid: 11, share: 7000 },
            { tokenid: 12, share: 8000 },
            { tokenid: 13, share: 9000 },
            { tokenid: 14, share: 10000 }
        ]).encodeABI()
    privKey = "d0343a504543b2524738bec135e204bb100967c286fc2fd9af9d465ba2b2e8b2";
    sender = "0x540881ECaF34C85EfB352727FC2F9858B19C4b08";
    const tx_nonce = await web3.eth.getTransactionCount(sender)
    const txData = {
        nonce: web3.utils.toHex(tx_nonce),
        gasLimit: web3.utils.toHex(6000000),
        gasPrice: web3.utils.toHex(web3.utils.toWei("20", 'Gwei')), // 10 Gwei
        to: vesting2ContractAddressRINKEBY,
        from: sender,
        data: approveEncodedABI
    }
    const signedTx = await web3.eth.accounts.signTransaction(txData, "0x" + privKey.toString('hex'));
    const result = await web3.eth.sendSignedTransaction(signedTx.raw || signedTx.rawTransaction);

    if (result.transactionHash) {
        console.log(`Successful Swap: https://ropsten.etherscan.io/tx/${result.transactionHash}`)
        return result.transactionHash
    } else if (result.error) {
        console.log('error', error);
        return error;
    } else {
        console.log('swap failed!')
        return
    }


})();
