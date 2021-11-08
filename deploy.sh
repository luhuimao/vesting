#!/bin/bash

script=./scripts/deploy.ts
network=$1
if [[ $network = "" ]]; then
    network=hardhat
fi
if [[ $network = "hardhat" ]]; then
    script=./scripts/deploy.ts
    #script=./scripts/deploy-hardhat.ts
fi
echo npx hardhat run $script --network $network
npx hardhat run $script --network $network

