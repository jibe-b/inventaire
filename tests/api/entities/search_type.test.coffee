CONFIG = require 'config'
__ = CONFIG.universalPath
_ = __.require 'builders', 'utils'
should = require 'should'
{ Promise } = __.require 'lib', 'promises'
{ nonAuthReq, undesiredErr } = require '../utils/utils'
{ createWork, randomLabel } = require '../fixtures/entities'
endpoint = '/api/entities?action=search-type'

describe 'entities:search-type', ->
  it 'should return a recently created entity', (done)->
    workLabel = randomLabel()
    createWork { labels: { fr: workLabel } }
    .delay 1000
    .then (creationRes)->
      createdWorkId = creationRes._id
      nonAuthReq 'get', "#{endpoint}&type=works&search=#{workLabel}&lang=fr"
      .get 'results'
      .then (results)->
        worksIds = _.map results, '_id'
        (createdWorkId in worksIds).should.be.true()
        results[0].uri.should.be.ok()
        done()
    .catch undesiredErr(done)

    return
