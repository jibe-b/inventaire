CONFIG = require 'config'
__ = CONFIG.universalPath
_ = __.require 'builders', 'utils'
error_ = __.require 'lib', 'error/error'
responses_ = __.require 'lib', 'responses'
sanitize = __.require 'lib', 'sanitize/sanitize'
sanitizeEntry = require './lib/resolver/sanitize_entry'
resolve = require './lib/resolver/resolve'

sanitization =
  edition:
    generic: 'object'
  works:
    generic: 'collection'
    optional: true
  authors:
    generic: 'collection'
    optional: true

module.exports = (req, res)->
  sanitize req, res, sanitization
  .then sanitizeEntry(res)
  .then resolve
  .then responses_.Wrap(res, 'result')
  .catch error_.Handler(req, res)
