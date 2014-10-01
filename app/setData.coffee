fs = require('fs')
filePath = __dirname + '/../data/AllSets-x.json'

# overrides the symbol image for the given set code
# this is used by the getSetSymbolImage to override 
# the default image lookup
setToImage = 
    'ITP' : ''
    'p15A': ''
    'pLPA': ''
    'pMGD': ''
    'pGPX': ''
    'pPRO': ''
    'pCMP': ''
    'pWPN': ''
    'pREL': ''
    'pMPR': ''
    'pELP': ''
    'pFNM': ''
    'pWOS': ''
    'pGRU': ''
    'pALP': ''
    'pJGP': ''
    'pPRE': ''
    'pCEL': ''
    'pDRC': ''
    'RQS' : ''
    'TSB' : '/symbol/set/TSP/c/16.png'
    'V14' : ''
    'VAN' : '/symbol/set/VAN/special/16.png'

# gets the symbol image for the given set, if one has been defined
getSetSymbolImage = (set) ->
    baseUrl = 'http://mtgimage.com'

    rarity = 'c'
    path = setToImage[set.code] ? "/symbol/set/#{set.code}/#{rarity}/16.png"

    if path then baseUrl + path

# read in all of the sets from the file
# the file should be an object where the key is the set code
# the key should also be uppercase
setMap = (->
    data = fs.readFileSync filePath, 'utf8'
    dataObj = JSON.parse(data)

    # create an object of the sets where the property is the uppercased code for the set
    (for own code, v of dataObj then v)
        .reduce ((obj, set) -> obj[set['code'].toUpperCase()] = set; obj), {}
)()

# create an array ordered by the release date desc
module.exports.sets =  ((jsonData) ->
    
    sortSetsByReleaseDateDesc = (set1, set2) ->
        return -1 if set1.releaseDate > set2.releaseDate
        return 1 if set1.releaseDate < set2.releaseDate
        return 0

    setsArray = (for setCode, set of jsonData 
        # create the URL for the small set symbol
        set.smallSymbolImageUrl = getSetSymbolImage set

        set
    ).sort(sortSetsByReleaseDateDesc)
    return setsArray
)(setMap)

# gets the set by the set code. if no set is mapped to the given
# code, then an undefined value is returned
module.exports.setByCode = (setCode) -> setMap[setCode.toUpperCase()]
    