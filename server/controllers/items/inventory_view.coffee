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
sanitize = __.require 'lib', 'sanitize/sanitize'
getItemsByUsers = require './lib/get_items_by_users'
getAuthorizedItems = require './lib/get_authorized_items'

sanitization =
  user: { optional: true }
  group: { optional: true }

module.exports = (req, res)->
  sanitize req, res, sanitization
  .then validateUserOrGroup
  .then getItems
  .then (items)->
    getItemsEntitiesData items
    .then bundleViewData(items)
  .then responses_.Send(res)
  .catch error_.Handler(req, res)

validateUserOrGroup = (params)->
  unless params.user or params.group
    throw error_.newMissingQuery 'user|group', 400, params
  return params

getItems = (params)->
  { user, group, reqUserId } = params
  if user then getAuthorizedItems.byUser user, reqUserId
  else getAuthorizedItems.byGroup group, reqUserId

getItemsEntitiesData = (items)->
  uris = _.uniq _.map(items, 'entity')
  getEntitiesByUris { uris }
  .get 'entities'
  .then replaceEditionsByTheirWork
