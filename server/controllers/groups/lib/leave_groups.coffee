CONFIG = require 'config'
__ = CONFIG.universalPath
_ = __.require 'builders', 'utils'
Group = __.require 'models', 'group'

# Working around the circular dependency
groups_ = null
lateRequire = -> groups_ = require './groups'
setTimeout lateRequire, 0

module.exports =
  userCanLeave: (userId, groupId)->
    groups_.byId groupId
    .then (group)->
      { admins, members } = group
      adminsIds = admins.map _.property('user')
      unless userId in adminsIds then return true
      mainUserIsTheOnlyAdmin = admins.length is 1
      thereAreOtherMembers = members.length > 0
      if mainUserIsTheOnlyAdmin and thereAreOtherMembers then false
      else true

  leaveAllGroups: (userId)->
    # TODO: check if userCanLeave
    groups_.byUser userId
    .map removeUser.bind(null, userId)
    .then groups_.db.bulk

removeUser = (userId, groupDoc)->
  if userId in groupDoc.admins
    _.warn arguments, "removing a user from a group she's admin of"

  for list in Group.attributes.usersLists
    groupDoc[list] = _.without groupDoc[list], userId

  return groupDoc
