__ = require('config').universalPath
_ = __.require 'builders', 'utils'

# Global conventions:
# - all error objects should have a statusCode (mimicking HTTP status codes)
#   this is already the case for errors rejected by bluereq and blue-cot

module.exports = (err, filter, context)->
  context = _.forceArray context
  # numbers filters are used as HTTP codes
  # while string will be taken as a type
  attribute = if _.isNumber(filter) then 'statusCode' else 'type'
  err[attribute] = filter

  # Prevent having an array in an array as context
  # or an array with a single object
  # This allows to return an object as context, with possibly data
  # the client can depend on
  if context.length is 1 and (_.isArray(context[0]) or _.isPlainObject(context[0]))
    context = context[0]

  err.context = context
  err.emitter = getErrorEmittingLines err
  return err

getErrorEmittingLines = (err)->
  err.stack.split '\n'
  .filter (line)-> not line.match(/lib\/error/)
  .slice 0, 5
  .map getErrorEmittingLine

getErrorEmittingLine = (line)->
  line?.trim()
  .replace /^\s*at\s+/, ''
  # delete parenthesis around the file path
  .replace /(\(|\))/g, ''
  # delete machine specific path
  .replace /[a-z_\/]+server/, ': server'
  .replace /[a-z_\/]+node_modules/, ': node_modules'
  # identify anonymous functions
  .replace /^:/, '(anonymous):'
