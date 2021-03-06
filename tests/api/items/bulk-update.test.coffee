should = require 'should'
{ authReq, authReqB, undesiredErr } = require '../utils/utils'
{ newItemBase } = require './helpers'

describe 'items:bulk-update', ->
  it 'should update an item details', (done)->
    authReq 'post', '/api/items', newItemBase()
    .then (item)->
      newTransaction = 'lending'
      item.transaction.should.not.equal newTransaction
      ids = [ item._id ]
      authReq 'put', '/api/items?action=bulk-update',
        ids: ids
        attribute: 'transaction'
        value: newTransaction
      .then (res)->
        res.ok.should.be.true()
        authReq 'get', "/api/items?action=by-ids&ids=#{ids.join('|')}"
        .get 'items'
        .then (updatedItems)->
          updatedItems[0].transaction.should.equal newTransaction
          done()
    .catch undesiredErr(done)

    return

  it 'should not update an item from another owner', (done)->
    authReq 'post', '/api/items', newItemBase()
    .then (item)->
      ids = [ item._id ]
      authReqB 'put', '/api/items?action=bulk-update',
        ids: ids
        attribute: 'transaction'
        value: 'lending'
      .catch (err)->
        err.statusCode.should.equal 400
        err.body.status_verbose.should.startWith 'user isnt item.owner'
        done()
    .catch undesiredErr(done)

    return
