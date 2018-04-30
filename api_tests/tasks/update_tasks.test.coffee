CONFIG = require 'config'
__ = CONFIG.universalPath
_ = __.require 'builders', 'utils'
should = require 'should'
{ authReq, adminReq } = require '../utils/utils'
{ merge } = require '../utils/entities'
{ collectEntities } = require '../fixtures/tasks'
{ createHuman } = require '../fixtures/entities'

collectEntitiesEndpoint = '/api/tasks?action=collect-entities'
bySuspectUri = '/api/tasks?action=by-suspect-uri&uri='
byScore = '/api/tasks?action=by-score'
updateEndpoint = '/api/tasks?action=update'

describe 'tasks:update', ->
  it 'should update a task', (done)->
    collectEntities()
    .then -> authReq 'get', byScore
    .get 'tasks'
    .then (tasks)->
      task = tasks[0]
      authReq 'put', updateEndpoint,
        id: task._id,
        attribute: 'state',
        value: 'dismissed'
      .then (updatedTask)->
        updatedTask[0].ok.should.be.true()
        done()
    .catch done

    return

  it 'should throw if invalid task id', (done)->
    authReq 'put', updateEndpoint,
      id: ''
    .catch (err)->
      err.body.status_verbose.should.be.a.String()
      done()
    .catch done

    return


describe 'tasks:merge-entities', ->
  it 'should update same suspect tasks to merged state', (done) ->
    createHuman { labels: { en: 'Jim Vance' } }
    .then (human)->
      adminReq 'post', collectEntitiesEndpoint
      .delay 2000
      .then -> authReq 'get', bySuspectUri + "inv:#{human._id}"
      .get 'tasks'
      .then (tasks)->
        task = tasks[0]
        anotherTask = tasks[1]
        merge task.suspectUri, task.suggestionUri
        .delay 100
        .then -> authReq 'get', "/api/tasks?action=by-ids&ids=#{anotherTask._id}"
        .get 'tasks'
        .then (tasks)->
          updatedTask = tasks[0]
          updatedTask.state.should.equal 'merged'
          done()
    .catch done

    return

  it 'should update task state to merged', (done) ->
    collectEntities()
    .then -> authReq 'get', byScore
    .get 'tasks'
    .then (tasks)->
      task = tasks[0]
      merge task.suspectUri, task.suggestionUri
      .delay 100
      .then -> authReq 'get', "/api/tasks?action=by-ids&ids=#{task._id}"
      .then (res)->
        updatedTask = res.tasks[0]
        updatedTask.state.should.equal 'merged'
        done()
    .catch done

    return

  it 'should update relationScore of tasks with same suspect', (done)->
    createHuman { labels: { en: 'Jim Vance' } }
    .then (suspect)->
      authReq 'post', collectEntitiesEndpoint
      .delay 1000
      .then -> authReq 'get', bySuspectUri + "inv:#{suspect._id}"
      .get 'tasks'
      .then (tasks)->
        taskToUpdate = tasks[0]
        otherTask = tasks[1]
        taskRelationScore = taskToUpdate.relationScore
        authReq 'put', updateEndpoint,
          id: taskToUpdate._id,
          attribute: 'state',
          value: 'dismissed'
        .delay 1000
        .then -> authReq 'get', "/api/tasks?action=by-ids&ids=#{otherTask._id}"
        .then (res)->
          updatedTask = res.tasks[0]
          updatedTask.relationScore.should.not.equal taskRelationScore
          done()
      .catch done

    return
