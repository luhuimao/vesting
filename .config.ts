export const VESTING1_ADDRESS_RINKEBY = "0x7490CF0DfC286948501349D88d5582da02193F97"; //REPLACE_FLAG
export const VESTING2_ADDRESS_RINKEBY = "0x8b997Ac1A1F526dD13ce4BB68925c3D9B4E65852"; //REPLACE_FLAG
export const STREAM1MULTINFTV2_ADDRESS_RINKEBY = ""; //REPLACE_FLAG
export const TEST_ERC721_ADDRESS_RINKEBY = "0x9Db201a9eA5b37Ce49480304fd34C42B3EBc10E3"; //REPLACE_FLAG
export const TEST_ERC20_ADDRESS_RINKEBY = "0x524A71eAaFC549Cbdf2013A9f9A7A356a9E54372"; //REPLACE_FLAG

export const STREAMV3_ADDRESS_RINKEBY = "0x8b201D78c8C2d1b06e9144CA73baBff013AfEcE0"; //REPLACE_FLAG
export const ERC721BATCHMINT_ADDRESS_RINKEBY = "0x49107F1c0cc743Af234EDCC7c1f76534f7F88119"; //REPLACE_FLAG
export const STREAMALIBV3_ADDRESS_RINKEBY = ""; //REPLACE_FLAG
export const TOKENALLOCLIBV3_ADDRESS_RINKEBY = "0x87Ed1BDD13E0B9Bd2c2499d51f9fE2392a70e7F7"; //REPLACE_FLAG

export function getStreamV3AddressByNetwork(networkName: string) {
    switch (networkName) {
        case 'rinkeby':
            return STREAMV3_ADDRESS_RINKEBY;
            break;
    }
    return null;
}

export function getERC721BatchMintAddressByNetwork(networkName: string) {
    switch (networkName) {
        case 'rinkeby':
            return ERC721BATCHMINT_ADDRESS_RINKEBY;
            break;
    }
    return null;
}

export function getTokenAllocLibV3AddressByNetwork(networkName: string) {
    switch (networkName) {
        case 'rinkeby':
            return TOKENALLOCLIBV3_ADDRESS_RINKEBY;
            break;
    }
    return null;
}

export function getStream1MultiNFTV2AddressByNetwork(networkName: string) {
    switch (networkName) {
        case 'rinkeby':
            return STREAM1MULTINFTV2_ADDRESS_RINKEBY;
            break;
    }
    return null;
}

export function getVesting1AddressByNetwork(networkName: string) {
    switch (networkName) {
        case 'rinkeby':
            return VESTING1_ADDRESS_RINKEBY;
            break;
    }
    return null;
}
export function getVesting2AddressByNetwork(networkName: string) {
    switch (networkName) {
        case 'rinkeby':
            return VESTING2_ADDRESS_RINKEBY;
            break;
    }
    return null;
}

export function getTESTERC20AddressByNetwork(networkName: string) {
    switch (networkName) {
        case 'rinkeby':
            return TEST_ERC20_ADDRESS_RINKEBY;
            break;
    }
    return null;
}

export function getTESTERC721AddressByNetwork(networkName: string) {
    switch (networkName) {
        case 'rinkeby':
            return TEST_ERC721_ADDRESS_RINKEBY;
            break;
    }
    return null;
}