console.time 'startup'
CONFIG = require 'config'
# Signal to other CONFIG consumers that they are in a server context
# and not simply scripts being executed in the wild
CONFIG.serverMode = true

__ = CONFIG.universalPath
_ = __.require 'builders', 'utils'

__.require('lib', 'startup/before')()

# Starting to make CouchDB initialization checks
couchInit = __.require('couch', 'init')()
# Meanwhile, start setting up the server.
# Startup time is mostly due to the time needed to require
# all files from controllers, middlewares, libs, etc
initExpress = require './server/init_express'

couchInit
.then _.Log('couch init')
.then initExpress
.tap -> console.timeEnd 'startup'
.then __.require('lib', 'startup/after')
.catch _.Error('init err')
