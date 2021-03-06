CONFIG = require('config')
__ = CONFIG.universalPath
_ = __.require 'builders', 'utils'
error_ = __.require 'lib', 'error/error'
assert_ = __.require 'utils', 'assert_types'

levelBase = __.require 'level', 'base'

db = levelBase.simpleSubDb 'cache'

{ offline } = CONFIG

{ oneMinute, oneDay, oneMonth } =  __.require 'lib', 'times'

module.exports =
  # - key: the cache key
  # - fn: a function with its context and arguments binded
  # - timespan: maximum acceptable age of the cached value in ms
  # - refresh: alias for timespan=0
  # - dry: return what's in cache or nothing: if the cache is empty, do not call the function
  # - dryFallbackValue: the value to return when no cached value can be found, to keep responses
  #   type consistent
  get: (params)->
    { key, fn, timespan, refresh, dry, dryAndCache, dryFallbackValue } = params
    if refresh
      timespan = 0
      dry = false
      dryAndCache = false
    timespan ?= oneMonth
    dry ?= false
    dryAndCache ?= false

    try
      assert_.string key
      unless dry then assert_.types [ 'function', 'number' ], [ fn, timespan ]
    catch err
      return error_.reject err, 500

    # Try to avoid cache miss when making a dry get
    # or when working offline (only useful in development)
    if dry or offline then timespan = Infinity

    # When passed a 0 timespan, it is expected to get a fresh value.
    # Refusing the old value is also a way to invalidate the current cache
    refuseOldValue = timespan is 0

    checkCache key, timespan
    .then requestOnlyIfNeeded(key, fn, dry, dryAndCache, dryFallbackValue, refuseOldValue)
    .catch (err)->
      label = "final cache_ err: #{key}"
      # not logging the stack trace in case of 404 and alikes
      if /^4/.test err.statusCode then _.warn err, label
      else _.error err, label

      throw err

  put: (key, value)->
    unless _.isNonEmptyString key then return error_.reject 'invalid key', 500

    unless value? then return error_.reject 'missing value', 500

    return putResponseInCache key, value

checkCache = (key, timespan)->
  db.get key
  .then (res)->
    # Returning nothing will trigger a new request
    unless res? then return

    { body, timestamp } = res

    # Reject outdated cached values
    unless isFreshEnough timestamp, timespan then return

    # In case there was nothing in cache
    if _.isEmpty body
      # Prevent re-requesting if it was already retried lately
      if isFreshEnough timestamp, 2 * oneDay
        # _.info key, 'empty cache value: retried lately'
        return res
      # Otherwise, trigger a new request by returning nothing
      # _.info key, 'empty cache value: retrying'
      return
    else
      return res

requestOnlyIfNeeded = (key, fn, dry, dryAndCache, dryFallbackValue, refuseOldValue)-> (cached)->
  if cached?
    # _.info "from cache: #{key}"
    return cached.body

  if dry
    # _.info "empty cache on dry get: #{key}"
    return dryFallbackValue

  if dryAndCache
    # _.info "returning and populating cache: #{key}"
    populate key, fn, refuseOldValue
    .catch _.Error("dryAndCache: #{key}")
    return dryFallbackValue

  return populate key, fn, refuseOldValue

populate = (key, fn, refuseOldValue)->
  fn()
  .then (res)->
    # _.info "from remote data source: #{key}"
    putResponseInCache key, res
    return res
  .catch (err)->
    if refuseOldValue
      _.warn err, "#{key} request err (returning nothing)"
      return
    else
      _.warn err, "#{key} request err (returning old value)"
      return returnOldValue key, err

putResponseInCache = (key, res)->
  # _.info "caching #{key}"
  db.put key,
    body: res
    timestamp: new Date().getTime()

isFreshEnough = (timestamp, timespan)-> not _.expired(timestamp, timespan)

returnOldValue = (key, err)->
  checkCache key, Infinity
  .then (res)->
    if res? then res.body
    else
      # rethrowing the previous error as it's probably more meaningful
      err.old_value = null
      throw err
