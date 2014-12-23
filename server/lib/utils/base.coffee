colors = require 'colors'
fs = require 'fs'

String::logIt = (label, color)->
  if color? then console.log "[" + label[color] + "] #{@toString()}"
  else console.log "[" + label['blue'] + "] #{@toString()}"
  return @toString()

module.exports =
  errorHandler: (res, err, status = 500)->
    if /^4/.test status then @warn err
    else @error new Error(err), err
    res.setHeader 'Content-Type', 'text/html'
    res.status status or 500
    # dont send the error details to the user
    res.end()

  mapCouchResult: (type, body)-> body.rows.map (el)-> el[type]
  mapCouchDoc: (body)-> @mapCouchResult 'doc', body

  getObjIfSuccess: (db, body)->
    if db.get? and body.ok
      return db.get(body.id)
    else if db.get?
      throw new Error "#{body.error}: #{body.reason}"
    else
      throw new Error "bad db object passed to _.getObjIfSuccess"

  jsonFile: (path)->
    JSON.parse fs.readFileSync(path).toString()

  areStringsOrFalsy: (array)->
    compacted = @compact(array)
    if compacted.length > 0 and @areStrings(compacted)
      return true
    else return false

  combinations: (array1, array2)->
    @types arguments, ['array', 'array']
    results = []
    array1.forEach (keys1)->
      array2.forEach (keys2)->
        results.push [keys1, keys2]
    return results

  timer: (fn, sync)->
    id = @now()
    console.time id
    if sync
      cb()
      console.timeEnd id
    else
      cb().then -> console.timeEnd id

# adapted from http://werxltd.com/wp/2010/05/13/javascript-implementation-of-javas-string-hashcode-method/
  hashCode: (string)->
    [hash, i, len] = [0, 0, string.length]
    if len is 0 then return hash

    while i < len
      chr = string.charCodeAt(i)
      hash = ((hash << 5) - hash) + chr
      hash |= 0 # Convert to 32bit integer
      i++
    Math.abs hash