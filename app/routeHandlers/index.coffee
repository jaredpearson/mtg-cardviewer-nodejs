
class IndexHandler 
	setup: (app) -> 

    	app.get '/', (req, res) -> 
        	res.render('index', {
            	title: 'Hello Title'
        	})


module.exports = IndexHandler
