lazypipe = require 'lazypipe'
p = (require 'gulp-load-plugins')()
mayuse = require('../../package').devDependencies

if not mayuse['gulp-using']
    console.log 'error: missing gulp-using'

pipechain = []

if mayuse['gulp-jshint']
    # get around the issue with the reporter
    p['jshint'] = require 'gulp-jshint'
    pipechain.push ['javascript', '.+\\.js']
    exports.javascript = (options) ->
        try
            reporter = options?.reporter ? null
            reporter or= 'jshint-stylish' if mayuse['jshint-stylish']
            require reporter
        catch error
            reporter = 'default'
        lazypipe()
            .pipe(p.using, {prefix: 'jscript'})
            .pipe(p.jshint)
            .pipe(p.jshint.reporter, reporter)

if mayuse['gulp-coffee'] or mayuse['gulp-iced']
    coffee = if mayuse['gulp-coffee'] then p.coffee else p.iced
    pipechain.push ['coffeescript', '.+\\.coffee']
    exports.coffeescript = (options) ->
        options ?= {bare: true}
        lazypipe()
            .pipe(p.using, {prefix: 'coffee'})
            .pipe(coffee, options)

if mayuse['gulp-iced']
    pipechain.push ['icedcoffeescript', '.+\\.iced']
    exports.icedcoffeescript = (options) ->
        options ?= {bare: true, runtime: 'inline'}
        lazypipe()
            .pipe(p.using, {prefix: 'iced'})
            .pipe(p.iced, options)

if mayuse['gulp-coffee'] and mayuse['gulp-iced']
    console.log 'warning: both gulp-coffee and gulp-iced imported'

if mayuse['gulp-haml']
    pipechain.push ['haml', '.+\\.haml']
    exports.haml = (options) ->
        lazypipe()
            .pipe(p.using, {prefix: 'haml'})
            .pipe(p.haml)

if mayuse['gulp-emblem']
    pipechain.push ['emblem', '.+\\.emblem']
    exports.emblem = (options) ->
        options ?=
            root: 'app/'
            outputType: 'node'
            wrapped: true
        lazypipe()
            .pipe(p.using, {prefix: 'emblem'})
            .pipe(p.emblem, options)

if mayuse['gulp-dust']
    pipechain.push ['dust', '.+\\.dust']
    exports.dust = (options) ->
        lazypipe()
            .pipe(p.using, {prefix: 'dust'})
            .pipe(p.dust, options)

if mayuse['gulp-handlebars']
    pipechain.push ['handlebars', '.+\\.hbs']
    exports.handlebars = (options) ->
        options ?=
            outputType: 'node'
            wrapped: true
        lazypipe()
            .pipe(p.using, {prefix: 'handlebars'})
            .pipe(p.handlebars, options)

if mayuse['gulp-uglify'] and mayuse['gulp-size']
    exports.uglify = (options) ->
        lazypipe()
            .pipe(p.using, {prefix: 'uglify'})
            .pipe(p.size, {showFiles: true})
            .pipe(p.uglify, options)
            .pipe(p.size, {showFiles: true})
else if mayuse['gulp-uglify'] and not mayuse['gulp-size']
    console.log 'warning: need gulp-size to uglify'

if mayuse['gulp-gzip'] and mayuse['gulp-size']
    exports.gzip = (options) ->
        lazypipe()
            .pipe(p.using, {prefix: 'gzip'})
            .pipe(p.gzip, options)
            .pipe(p.size, {showFiles: true})
else if mayuse['gulp-gzip'] and not mayuse['gulp-size']
    console.log 'warning: need gulp-size to gzip'

# create a pipe with options, attach an error handler
exports.linked_pipe = (pipefun, error, options) ->
    result = pipefun(options)()
    result.on 'error', error

if mayuse['gulp-if']
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
