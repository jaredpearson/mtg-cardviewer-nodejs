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

            res.render('setView', {
                title: 'Set ',
                set: set,
                cards: cards
            })

module.exports = SetResourceHandler