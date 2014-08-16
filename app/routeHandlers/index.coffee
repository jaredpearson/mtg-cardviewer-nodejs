setData = require('../setData')

# create the handler
class IndexHandler 
    setup: (app) -> 

        app.get '/', (req, res) -> 
            res.render('index', {
                title: 'MTG - Card Viewer'
                sets: setData.sets
            })


module.exports = IndexHandler
