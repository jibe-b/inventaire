CONFIG = require 'config'
__ = CONFIG.universalPath
_ = __.require 'builders', 'utils'
error_ = __.require 'lib', 'error/error'
images_ = __.require 'lib', 'images'
endpoint = CONFIG.images.localEndpoint()
{ maxSize } = CONFIG.images
request = require 'request'
qs = require 'querystring'
{ oneYear } =  __.require 'lib', 'times'
{ offline } = CONFIG
{ localGateway, publicGateway } = CONFIG.ipfs

# resized images urls looks like /img/#{w}x#{h}/(#{hash}.jpg|#{external url hashCode?href=escaped url})"

module.exports = (req, res, next)->
  # could be useful in development
  # while hereafter image streams' error
  # aren't correctly handled
  if offline then return _.okWarning res, 'you are in offline mode: no img delivered'
  [ dimensions, rest ] = parseReq req

  # if no dimensions are passed, should return the maximum dimension
  unless /\d{2,4}x\d{2,4}/.test dimensions
    rest = dimensions
    dimensions = null

  if /^[0-9a-f]{40}.jpg$/.test rest
    url = "#{endpoint}#{rest}"

  else if /^[0-9]+$/.test rest
    url = req.query.href
    unless _.isUrl url
      return error_.bundle req, res, 'invalid href query', 400

    urlCode = _.hashCode(url).toString()
    # The hashcode can be used by Nginx for caching, while the url is passed
    # as query argument in case it isnt in cache.
    # Here, we just check that we do get the same hash
    unless urlCode is rest
      return error_.bundle req, res, 'hash code and href dont match', 400

    # Optimize where to fetch IPFS resources
    if url.startsWith publicGateway
      # The local gateway might already have the requested image in cache
      # and should be way closer on the network
      url = url.replace publicGateway, localGateway

  else
    return error_.bundle req, res, 'invalid image path', 400, rest

  getResizeImage req, res, url, dimensions

getResizeImage = (req, res, url, dimensions)->
  [ width, height ] = dimensions?.split('x') or [maxSize, maxSize]
  [ width, height ] = images_.applyLimits width, height

  res.header 'Content-Type', 'image/jpeg'
  res.header 'Cache-Control', "public, max-age=#{oneYear}"

  alreadySent = false
  handleBufferError = (buf)->
    err = new Error(buf.toString())
    error_.handler req, res, err
    alreadySent = true

  images_.shrinkStream request(url), width, height
  .stream (err, stdout, stderr)->
    if err? then return error_.handler req, res, err
    stdout.on 'error', handleBufferError
    stderr.on 'data', handleBufferError

    # Non of the above seem to catch errors for the case when graphicsmagick isn't installed
    # so instead of doing `stdout.pipe(res)`, we check if data was actually passed
    # before determining if it is a success or an error
    receivedData = false
    stdout.on 'data', (data)->
      receivedData = true
      res.write data

    stdout.on 'close', (data)->
      # Addresses the case when the response was already sent by an error handler
      if alreadySent then return
      if receivedData then res.end()
      # usually solved by `sudo apt-get install graphicsmagick`
      else error_.bundle req, res, 'empty graphicsmagick response: make sure graphicsmagick is installed on the server', 500

parseReq = (req)->
  { pathname } = req._parsedUrl
  pathname = pathname.replace '/img/', ''
  return pathname.split '/'
