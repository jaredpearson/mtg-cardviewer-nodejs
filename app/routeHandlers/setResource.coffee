setData = require('../setData')
cardData = require('../cardData')

# create a stripped down version of the card for serialization to the 
# browser to optimize data transfer
createCardUiModels = (set, cards) ->
    for card in cards

        # split the raw mana cost value into it's parts
        # mana costs are usually written like {2}{G}{B}
        manaCostParts = (
            regex = /\{([^\}]*)\}/g
            while match = regex.exec(card.manaCost) then match[1]
        )

        {
            name: card.name
            fullImageUrl: "http://mtgimage.com/actual/set/#{set.code.toLowerCase()}/#{card.imageName}.hq.jpg" 
            manaCost: {
                raw: card.manaCost
                parts: manaCostParts
            }
            type: card.type
            number: card.number
        }

createSetUiModels = (sets) ->
    for set in sets
        {
            name: set.name
            code: set.code
            smallSymbolImageUrl: set.smallSymbolImageUrl
        }


class SetResourceHandler
    setup: (app) -> 
        app.get '/sets/:code', => @handleShowSet arguments...
        app.get '/sets/:code/cards.json', => @handleGetCardsAsJson arguments...
            
    handleShowSet: (req, res) ->
        if !req.params.code?
            err = new Error('Unable to find resource')
            err.status = 404
            throw err

        set = setData.setByCode req.params.code
        if !set?
            err = new Error('Unable to find resource')
            err.status = 404
            throw err

        cards = cardData.cardsBySet set.code

        cardsAsJson = JSON.stringify(createCardUiModels(set, cards));
        
        sets = setData.sets

        res.render('setView', {
            title: set.name
            bodyClass: 'setView'
            set: set
            cardsAsJson: cardsAsJson
            setsAsJson: JSON.stringify(createSetUiModels(sets))
        })

    handleGetCardsAsJson: (req, res) ->
        if !req.params.code?
            err = new Error('Unable to find resource')
            err.status = 404
            throw err

        set = setData.setByCode req.params.code
        if !set?
            err = new Error('Unable to find resource')
            err.status = 404
            throw err

        cards = cardData.cardsBySet set.code

        res.json(createCardUiModels(set, cards))

module.exports = SetResourceHandler