setData = require('./setData')

# gets the cards associated to the specified set code
module.exports.cardsBySet = (setCode) ->
    set = setData.setByCode(setCode)
    if !set? then throw "No set found for #{setCode}"
    set.cards