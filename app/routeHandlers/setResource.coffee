setData = require('../setData')
cardData = require('../cardData')

# create a stripped down version of the card for serialization to the 
# browser to optimize data transfer
class CardUiModel
    constructor: (card, set) ->

        # split the raw mana cost value into it's parts
        # mana costs are usually written like {2}{G}{B}
        manaCostParts = (
            regex = /\{([^\}]*)\}/g
            while match = regex.exec(card.manaCost) then match[1]
        )

        @data = {
            name: card.name
            fullImageUrl: "http://mtgimage.com/actual/set/#{set.code.toLowerCase()}/#{card.imageName}.hq.jpg" 
            manaCost: {
                raw: card.manaCost
                parts: manaCostParts
            }
            type: card.type
        }

    # gets the card as a simple object
    getFieldsAsObject: -> @data


class SetResourceHandler
    setup: (app) -> 
        app.get '/sets/:code', => @handle arguments...
            
    handle: (req, res) ->
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

        cardsAsJson = this.createCardsAsJson(set, cards);

        res.render('setView', {
            title: set.name
            bodyClass: 'setView'
            set: set
            cardsAsJson: cardsAsJson
            cards: cards
        })

    createCardsAsJson: (set, cards) ->

        uiCardsArray = (for card in cards
            new CardUiModel(card, set).getFieldsAsObject()
        )
        JSON.stringify(uiCardsArray)

module.exports = SetResourceHandler