__ = require('config').universalPath
_ = __.require 'builders', 'utils'
promises_ = __.require 'lib', 'promises'
responses_ = __.require 'lib', 'responses'
error_ = __.require 'lib', 'error/error'
items_ = require './lib/items'
user_ = __.require 'controllers', 'user/lib/user'
getEntitiesByUris = __.require 'controllers', 'entities/lib/get_entities_by_uris'
getByAccessLevel = require './lib/get_by_access_level'
replaceEditionsByTheirWork = require './lib/view/replace_editions_by_their_work'
bundleViewData = require './lib/view/bundle_view_data'

module.exports = (req, res)->
  { _id: reqUserId } = req.user

  getAllNetworkItems reqUserId
  .then (items)->
    getItemsEntitiesData items
    .then bundleViewData(items)
  .then responses_.Send(res)
  .catch error_.Handler(req, res)

getAllNetworkItems = (reqUserId)->
  user_.getNetworkIds reqUserId
  .then getItems(reqUserId)
  .then _.flatten

getItems = (reqUserId)-> (ids)->
  promises_.all [
    items_.byOwner reqUserId
    getByAccessLevel.network ids, reqUserId
  ]

getItemsEntitiesData = (items)->
  uris = _.uniq items.map(_.property('entity'))
  getEntitiesByUris { uris }
  .get 'entities'
  .then replaceEditionsByTheirWork
