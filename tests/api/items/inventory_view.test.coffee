CONFIG = require 'config'
__ = CONFIG.universalPath
_ = __.require 'builders', 'utils'
should = require 'should'
{ getUser, getUserB, authReq, undesiredErr, undesiredRes } = __.require 'apiTests', 'utils/utils'
{ createItem, createItems } = require '../fixtures/items'
endpoint = '/api/items?action=inventory-view'

describe 'items:inventory-view', ->
  it 'should return a view of the inventory', (done)->
    authReq 'get', endpoint
    .then (res)->
      res.worksTree.should.be.an.Object()
      res.worksTree.owner.should.be.an.Object()
      res.workUriItemsMap.should.be.an.Object()
      res.itemsByDate.should.be.an.Array()
      done()
    .catch done

    return
