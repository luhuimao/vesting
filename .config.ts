export const VESTING1_ADDRESS_RINKEBY = "0xFa6CB842f240671FE835c5c3D97132aB47a056B5"; //REPLACE_FLAG
export const VESTING2_ADDRESS_RINKEBY = "0x2880c5Cfb7BB84784BD465CC850bd2bf701cC66F"; //REPLACE_FLAG

export const TEST_ERC721_ADDRESS_RINKEBY = "0x9Db201a9eA5b37Ce49480304fd34C42B3EBc10E3"; //REPLACE_FLAG
export const TEST_ERC20_ADDRESS_RINKEBY = "0x524A71eAaFC549Cbdf2013A9f9A7A356a9E54372"; //REPLACE_FLAG

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