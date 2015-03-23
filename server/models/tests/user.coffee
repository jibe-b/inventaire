CONFIG = require 'config'
__ = CONFIG.root
_ = __.require 'builders', 'utils'
{Username, Email} = require './common-tests'

module.exports =
  username: (username)-> Username.test(username)
  email: (username)-> Email.test(username)
  password: (password)->  8 <= password.length <=60
  language: (lang)-> /^\w{2}$/.test(lang)
  picture: (picture)-> _.isUrl(picture)
  creationStrategy: (creationStrategy)->
    creationStrategy in ['browserid', 'local']
