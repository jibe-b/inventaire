CONFIG = require 'config'
__ = CONFIG.universalPath
_ = __.require 'builders', 'utils'
{ Promise } = __.require 'lib', 'promises'
entities_ = require '../entities'
getInvEntityCanonicalUri = require '../get_inv_entity_canonical_uri'

module.exports = (edition)->
  { isbn } = edition

  resolveIsbn isbn
  .then (uri)-> if uri then edition.uri = uri

resolveIsbn = (isbn)->
  unless isbn? then return Promise.resolved

  entities_.byIsbn isbn
  .then (entity)->
    if entity?
      uri = getInvEntityCanonicalUri(entity)[0]
      return uri
