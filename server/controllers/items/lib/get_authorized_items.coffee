__ = require('config').universalPath
_ = __.require 'builders', 'utils'
getByAccessLevel = require './get_by_access_level'
user_ = __.require 'controllers', 'user/lib/user'
groups_ = __.require 'controllers', 'groups/lib/groups'

# Return what the reqUserId user is allowed to see from a user or a group inventory
module.exports =
  byUser: (userId, reqUserId)->
    if userId is reqUserId then return getByAccessLevel.private userId

    user_.areFriendsOrGroupCoMembers userId, reqUserId
    .then (usersAreFriendsOrGroupCoMembers)->
      if usersAreFriendsOrGroupCoMembers then getByAccessLevel.network userId
      else getByAccessLevel.public userId

  byGroup: (groupId, reqUserId)->
    groups_.getGroupMembersIds groupId
    .then (allGroupMembers)->
      if reqUserId in allGroupMembers then getByAccessLevel.network allGroupMembers
      else getByAccessLevel.public allGroupMembers
