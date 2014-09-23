express = require('express')
expressHbs = require('express-handlebars')
logfmt = require('logfmt')
path = require('path')
stylus = require('stylus')
util = require('util')


module.exports.setup = (app, routesCallback) -> 
    
    app.use logfmt.requestLogger()

    # --------------------------------------
    # setup the view engine (handlebars)
    # --------------------------------------
    app.engine('hbs', expressHbs({extname:'hbs', defaultLayout:'main.hbs'}));
    app.set('view engine', 'hbs');


    # --------------------------------------
    # setup the css preprocessor (stylus)
    # --------------------------------------
    app.use stylus.middleware {
        src: path.join(__dirname, '../stylus'),
        dest: path.join(__dirname, '../public/css')
        compile: (str, path) -> 
            return stylus(str).set('filename', path)
    }


    # --------------------------------------
    # setup the application routes
    # --------------------------------------
    routesCallback(app);


    # --------------------------------------
    # setup the static 'public' pages
    # --------------------------------------
    app.use express.static(path.join(__dirname, '../public'))


    # --------------------------------------
    # standard error handling
    # --------------------------------------
    # catch 404 and forward to error handler
    app.use((req, res, next) ->
        err = new Error('Not Found');
        err.status = 404;
        next(err);
    )

    # production error handler
    # no stacktraces leaked to user
    app.use((err, req, res, next) -> 
        util.error('Error Occurred: ' + err);
        util.error(err.stack);
        res.status(err.status || 500)
        res.render('error', {
            title: 'Error Occurred',
            message: err.message,
            error: {}
        })
    )
