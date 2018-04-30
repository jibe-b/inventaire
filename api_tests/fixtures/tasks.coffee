CONFIG = require 'config'
__ = CONFIG.universalPath
_ = __.require 'builders', 'utils'
{ authReq, adminReq } = require '../utils/utils'
promises_ = __.require 'lib', 'promises'
randomString = __.require 'lib', './utils/random_string'
{ createHuman, createWorkWithAuthor } = require './entities'
collectEntitiesEndpoint = '/api/tasks?action=collect-entities'
collectEntitiesPromise = null

createHumanAndCollectEntities = ->
  # Make sure there is at least one human in the database
  createHuman { labels: { en: 'Stanislas Lem' } }
  .then (human)->
    adminReq 'post', collectEntitiesEndpoint
    .delay 2000
    .then (res)->
      res.human = human
      return res

module.exports = API =
  collectEntities: (params = {})->
    if not collectEntitiesPromise? or params.refresh
      collectEntitiesPromise = createHumanAndCollectEntities()
    return collectEntitiesPromise
