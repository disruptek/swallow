lazypipe = require "lazypipe"
p = (require "gulp-load-plugins")()

if not p.using
    console.log 'error: missing gulp-using'

pipechain = []

if p.jshint
    pipechain.push ['javascript', '.+\\.js']
    exports.javascript = (options) ->
        try
            reporter = options?.reporter ? 'jshint-stylish'
            require reporter
        catch error
            reporter = 'default'
        lazypipe()
            .pipe(p.using)
            .pipe(p.jshint)
            .pipe(p.jshint.reporter, reporter)

if p.iced or p.coffee
    pipechain.push ['coffeescript', '.+\\.coffee']
    exports.coffeescript = (options) ->
        options ?= {bare: true}
        lazypipe()
            .pipe(p.using)
            .pipe(p.iced or p.coffee, options)

if p.iced
    pipechain.push ['icedcoffeescript', '.+\\.iced']
    exports.icedcoffeescript = (options) ->
        options ?= {bare: true}
        lazypipe()
            .pipe(p.using)
            .pipe(p.iced, options)

if p.iced and p.coffee
    console.log 'warning: both gulp-coffee and gulp-iced imported'

if p.haml
    pipechain.push ['haml', '.+\\.haml']
    exports.haml = (options) ->
        lazypipe()
            .pipe(p.using)
            .pipe(p.haml)

if p.emblem
    pipechain.push ['emblem', '.+\\.emblem']
    exports.emblem = (options) ->
        options ?=
            root: 'app/'
            outputType: 'node'
            wrapped: true
        lazypipe()
            .pipe(p.using)
            .pipe(p.emblem, options)

if p.dust
    pipechain.push ['dust', '.+\\.dust']
    exports.dust = (options) ->
        lazypipe()
            .pipe(p.using)
            .pipe(p.dust, options)

if p.handlebars
    pipechain.push ['handlebars', '.+\\.hbs']
    exports.handlebars = (options) ->
        options ?=
            outputType: 'node'
            wrapped: true
        lazypipe()
            .pipe(p.using)
            .pipe(p.handlebars, options)

if p.uglify and p.size
    exports.uglify = (options) ->
        lazypipe()
            .pipe(p.size, {showFiles: true})
            .pipe(p.uglify, options)
            .pipe(p.size, {showFiles: true})
else if p.uglify or p.size
    console.log 'warning: need both gulp-uglify and gulp-size'

if p.gzip and p.size
    exports.gzip = (options) ->
        lazypipe()
            .pipe(p.gzip, options)
            .pipe(p.size, {showFiles: true})
else if p.gzip or p.size
    console.log 'warning: need both gulp-gzip and gulp-size'

# create a pipe with options, attach an error handler
exports.linked_pipe = (pipefun, error, options) ->
    result = pipefun(options)()
    result.on 'error', error

if p.if
    # a pipe that turns everything into javascript
    exports.chain = (incoming, error) ->
        pipeline = incoming
        for recipe in pipechain
            [fun, re] = [exports[recipe[0]], new RegExp(recipe[1])]
            pipe = exports.linked_pipe(fun, error)
            pipeline = pipeline.pipe(p.if(re, pipe))
        return pipeline
else
    console.log 'warning: need gulp-if for compile_chain'
