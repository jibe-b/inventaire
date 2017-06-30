CONFIG = require 'config'
__ = CONFIG.universalPath
_ = __.require 'builders', 'utils'
should = require 'should'
{ Promise } = __.require 'lib', 'promises'
{ nonAuthReq, authReq, undesiredRes, undesiredErr, getUser } = __.require 'apiTests', 'utils/utils'
randomString = __.require 'lib', './utils/random_string'

describe 'search:global', ->
  it 'should reject empty searches', (done)->
    nonAuthReq 'get', '/api/search?lang=fr&types=works'
    .then undesiredRes(done)
    .catch (err)->
      err.statusCode.should.equal 400
      err.body.status_verbose.should.equal 'missing parameter in query: search'
      done()
    .catch undesiredErr(done)

    return

  it 'should reject search without types', (done)->
    nonAuthReq 'get', '/api/search?search=yo&lang=fr'
    .then undesiredRes(done)
    .catch (err)->
      err.statusCode.should.equal 400
      err.body.status_verbose.should.equal 'missing parameter in query: types'
      done()
    .catch undesiredErr(done)

    return

  it 'should reject invalid types', (done)->
    nonAuthReq 'get', '/api/search?search=yo&types=da&lang=fr'
    .then undesiredRes(done)
    .catch (err)->
      err.statusCode.should.equal 400
      err.body.status_verbose.should.equal 'invalid type: da'
      done()
    .catch undesiredErr(done)

    return

  it 'should reject search without lang', (done)->
    nonAuthReq 'get', '/api/search?search=yo&types=works'
    .then undesiredRes(done)
    .catch (err)->
      err.statusCode.should.equal 400
      err.body.status_verbose.should.equal 'missing parameter in query: lang'
      done()
    .catch undesiredErr(done)

    return

  it 'should return a wikidata human', (done)->
    nonAuthReq 'get', '/api/search?search=Gilles%20Deleuze&types=humans&lang=fr'
    .then (res)->
      { results } = res
      results.should.be.an.Array()
      results.forEach (result)-> result.type.should.equal 'humans'
      _.pluck(results, 'id').includes('Q184226').should.be.true()
      done()
    .catch undesiredErr(done)

    return

  it 'should return a local human', (done)->
    label = randomString 5
    authReq 'post', '/api/entities?action=create',
      labels: { fr: label }
      claims: { 'wdt:P31': [ 'wd:Q5' ] }
    # Let the time for Elastic Search indexation
    .delay 1000
    .then (entity)->
      nonAuthReq 'get', "/api/search?search=#{label}&types=humans&lang=fr"
      .then (res)->
        { results } = res
        results.should.be.an.Array()
        results.forEach (result)-> result.type.should.equal 'humans'
        _.pluck(results, 'id').includes(entity._id).should.be.true()
        done()
    .catch undesiredErr(done)

    return

  it 'should return a local work', (done)->
    label = randomString 5
    authReq 'post', '/api/entities?action=create',
      labels: { fr: label }
      claims: { 'wdt:P31': [ 'wd:Q571' ] }
    # Let the time for Elastic Search indexation
    .delay 1000
    .then (entity)->
      nonAuthReq 'get', "/api/search?search=#{label}&types=works&lang=fr"
      .then (res)->
        { results } = res
        results.should.be.an.Array()
        results.forEach (result)-> result.type.should.equal 'works'
        _.pluck(results, 'id').includes(entity._id).should.be.true()
        done()
    .catch undesiredErr(done)

    return

  it 'should return a wikidata work', (done)->
    nonAuthReq 'get', '/api/search?search=Les%20Misérables&types=works&lang=fr'
    .then (res)->
      { results } = res
      results.should.be.an.Array()
      results.forEach (result)-> result.type.should.equal 'works'
      _.pluck(results, 'id').includes('Q180736').should.be.true()
      done()
    .catch undesiredErr(done)

    return

  it 'should return a local serie', (done)->
    label = randomString 5
    authReq 'post', '/api/entities?action=create',
      labels: { fr: label }
      claims: { 'wdt:P31': [ 'wd:Q277759' ] }
    # Let the time for Elastic Search indexation
    .delay 1000
    .then (entity)->
      nonAuthReq 'get', "/api/search?search=#{label}&types=series&lang=fr"
      .then (res)->
        { results } = res
        results.should.be.an.Array()
        results.forEach (result)-> result.type.should.equal 'series'
        _.pluck(results, 'id').includes(entity._id).should.be.true()
        done()
    .catch undesiredErr(done)

    return

  it 'should return a wikidata serie', (done)->
    nonAuthReq 'get', '/api/search?search=Harry%20Potter&types=series&lang=fr'
    .then (res)->
      { results } = res
      results.should.be.an.Array()
      results.forEach (result)-> result.type.should.equal 'series'
      _.pluck(results, 'id').includes('Q8337').should.be.true()
      done()
    .catch undesiredErr(done)

    return

  it 'should return a user', (done)->
    getUser()
    .delay 1000
    .then (user)->
      { username } = user
      nonAuthReq 'get', "/api/search?search=#{username}&types=users&lang=fr"
      .then (res)->
        { results } = res
        results.should.be.an.Array()
        results.forEach (result)-> result.type.should.equal 'users'
        _.pluck(results, 'id').includes(user._id).should.be.true()
        done()
    .catch undesiredErr(done)

    return

  it 'should return a group', (done)->
    name = randomString 5
    authReq 'post', '/api/groups?action=create', { name }
    .delay 1000
    .then (group)->
      nonAuthReq 'get', "/api/search?search=#{name}&types=groups&lang=fr"
      .then (res)->
        { results } = res
        results.should.be.an.Array()
        results.forEach (result)-> result.type.should.equal 'groups'
        _.pluck(results, 'id').includes(group._id).should.be.true()
        done()
    .catch undesiredErr(done)

    return