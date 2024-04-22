export const getUri = (nft: string) => {
    const uris: string[] = []
    if (nft == 'SNBFarmer') {
        uris.push('')
        uris.push('')
        uris.push('')
        uris.push('')
        uris.push('')
        uris.push('')
        uris.push('')
        uris.push('')
        uris.push('')
        uris.push('')
    } else if (nft == 'SNBNarc') {
        uris.push('')
        uris.push('')
        uris.push('')
        uris.push('')
        uris.push('')
        uris.push('')
        uris.push('')
        uris.push('')
        uris.push('')
        uris.push('')
    } else if (nft == 'SNBStoner') {
        uris.push('')
    } else if (nft == 'SNBInformant') {
        uris.push('')
    }
    return uris
}
