
express = require('express')
bootstrap = require('./app/bootstrap.coffee')
port = Number(process.env.PORT || 5000)


app = express()
bootstrap.setup app, (app) -> 

	console.log 'Finding routeHandlers'
	for handlerName in ['index', 'setResource', 'searchResource']
    	Handler = require './app/routeHandlers/' + handlerName + '.coffee'
    	(new Handler()).setup app

server = app.listen port, -> 
    console.log 'Listening on ' + server.address().port