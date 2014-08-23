setData = require('../setData')
cardData = require('../cardData')

class SetResourceHandler
    setup: (app) -> 
        app.get '/sets/:code', (req, res) =>
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
                title: 'Set '
                set: set
                cardsAsJson: cardsAsJson
                cards: cards
            })

    createCardsAsJson: (set, cards) ->

        uiCardsArray = (for card in cards
            cleanCardName = card.name.replace('Æ', 'AE').toLowerCase()

            {
                name: card.name
                fullImageUrl: "http://mtgimage.com/actual/set/#{set.code.toLowerCase()}/#{cleanCardName}.hq.jpg" 
            } 
        )
        JSON.stringify(uiCardsArray)

module.exports = SetResourceHandler