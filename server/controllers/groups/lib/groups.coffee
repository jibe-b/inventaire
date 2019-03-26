CONFIG = require 'config'
__ = CONFIG.universalPath
_ = __.require 'builders', 'utils'
promises_ = __.require 'lib', 'promises'
error_ = __.require 'lib', 'error/error'
Group = __.require 'models', 'group'

db = __.require('couch', 'base')('groups')

module.exports = groups_ =
  db: db
  # using a view to avoid returning users or relations
  byId: db.viewFindOneByKey.bind db, 'byId'
  bySlug: db.viewFindOneByKey.bind db, 'bySlug'
  byUser: db.viewByKey.bind db, 'byUser'
  byInvitedUser: db.viewByKey.bind db, 'byInvitedUser'
  byAdmin: (userId)->
    # could be simplified by making the byUser view
    # emit an arrey key with the role as second parameter
    # but it would make groups_.byUser more complex
    # (i.e. use a range instead of a simple key)
    db.viewByKey 'byUser', userId
    .filter Group.userIsAdmin.bind(null, userId)

  # /!\ the 'byName' view does return groups with 'searchable' set to false
  nameStartBy: (name, limit = 10)->
    name = name.toLowerCase()
    db.viewCustom 'byName',
      startkey: name
      endkey: name + 'Z'
      include_docs: true
      limit: limit

  # including invitations
  allUserGroups: (userId)->
    promises_.all [
      groups_.byUser(userId)
      groups_.byInvitedUser(userId)
    ]
    .spread _.union.bind(_)

  create: (options)->
    promises_.try -> Group.create options
    .then addSlug
    .then db.postAndReturn
    .then _.Log('group created')

  findUserGroupsCoMembers: (userId)->
    groups_.byUser userId
    .then groups_.allGroupsMembers
    # Deduplicate and remove the user own id from the list
    .then (usersIds)-> _.uniq _.without(usersIds, userId)

  userInvited: (userId, groupId)->
    groups_.byId groupId
    .then _.partial(Group.findInvitation, userId, _, true)

  byCreation: (limit = 10)->
    db.viewCustom 'byCreation', { limit, descending: true, include_docs: true }

  getGroupMembersIds: (groupId)->
    groups_.byId groupId
    .then (group)->
      unless group? then throw error_.notFound { group: groupId }
      return Group.getAllMembers group

groups_.byPosition = __.require('lib', 'by_position')(db, 'groups')

membershipActions = require('./membership_actions')(db)
usersLists = require './users_lists'
updateSettings = require './update_settings'
counts = require './counts'
leaveGroups = require './leave_groups'
getSlug = require './get_slug'

addSlug = (group)->
  getSlug group.name, group._id
  .then (slug)->
    group.slug = slug
    return group

_.extend groups_, membershipActions, usersLists, counts, leaveGroups, {
  updateSettings,
  getSlug,
  addSlug,
  getGroupData: require './group_public_data'
}
