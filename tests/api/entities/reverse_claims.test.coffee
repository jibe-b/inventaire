CONFIG = require 'config'
__ = CONFIG.universalPath
_ = __.require 'builders', 'utils'
should = require 'should'
{ nonAuthReq, undesiredErr, undesiredRes } = require '../utils/utils'

describe 'entities:reverse-claims', ->
  it 'should reject wdt:P31 requests', (done)->
    url = _.buildPath '/api/entities',
      action: 'reverse-claims'
      property: 'wdt:P31'
      uri: 'wd:Q571'
    nonAuthReq 'get', url
    .then undesiredRes(done)
    .catch (err)->
      err.body.status_verbose.should.equal 'blacklisted property'
      done()
    .catch undesiredErr(done)

    return
