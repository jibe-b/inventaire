CONFIG = require 'config'
__ = CONFIG.universalPath
_ = __.require 'builders', 'utils'
should = require 'should'
{ getUser, getUserB, authReq, undesiredErr, undesiredRes } = __.require 'apiTests', 'utils/utils'
endpoint = '/api/items?action=inventory-view'
{ groupPromise } = require '../fixtures/groups'
{ createUserWithItems } = require '../fixtures/populate'

describe 'items:inventory-view', ->
  it 'should reject requests without a user or a group', (done)->
    authReq 'get', endpoint
    .then undesiredRes(done)
    .catch (err)->
      err.statusCode.should.equal 400
      err.body.status_verbose.should.equal 'missing parameter in query: user or group'
      done()
    .catch done

    return

  it 'should return a user inventory-view', (done)->
    createUserWithItems()
    .get '_id'
    .then (userId)-> authReq 'get', "#{endpoint}&user=#{userId}"
    .then (res)->
      res.worksTree.should.be.an.Object()
      res.worksTree.author.should.be.an.Object()
      res.worksTree.genre.should.be.an.Object()
      res.worksTree.subject.should.be.an.Object()
      res.worksTree.owner.should.be.an.Object()
      res.workUriItemsMap.should.be.an.Object()
      res.itemsByDate.should.be.an.Array()
      done()
    .catch done

    return

  it 'should return a group inventory-view', (done)->
    groupPromise
    .get '_id'
    .then (groupId)-> authReq 'get', "#{endpoint}&group=#{groupId}"
    .then (res)->
      res.worksTree.should.be.an.Object()
      res.worksTree.author.should.be.an.Object()
      res.worksTree.genre.should.be.an.Object()
      res.worksTree.subject.should.be.an.Object()
      res.worksTree.owner.should.be.an.Object()
      res.workUriItemsMap.should.be.an.Object()
      res.itemsByDate.should.be.an.Array()
      done()
    .catch done

    return
