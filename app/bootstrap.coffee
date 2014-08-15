express = require('express')
expressHbs = require('express-handlebars')
logfmt = require('logfmt')
path = require('path')


module.exports.setup = (app, routesCallback) -> 
    
    app.use logfmt.requestLogger()

    # --------------------------------------
    # setup the view engine
    # --------------------------------------
    app.engine('hbs', expressHbs({extname:'hbs', defaultLayout:'main.hbs'}));
    app.set('view engine', 'hbs');


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

    # development error handler
    # will print stacktrace
    if app.get('env') == 'development' 
        app.use((err, req, res, next) -> 
            res.status(err.status || 500)
            res.render('error', {
                title: 'Error Occurred',
                message: err.message,
                error: err
            })
        )


    # production error handler
    # no stacktraces leaked to user
    app.use((err, req, res, next) -> 
        res.status(err.status || 500)
        res.render('error', {
            title: 'Error Occurred',
            message: err.message,
            error: {}
        })
    )
