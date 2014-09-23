setData = require('../setData')

# create the handler
class IndexHandler 
    setup: (app) -> 
        app.get '/', this.handle

    handle: (req, res) ->
        res.render('index', {
            sets: setData.sets
        })


module.exports = IndexHandler
