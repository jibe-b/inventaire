CONFIG = require 'config'
__ = CONFIG.universalPath
_ = __.require 'builders', 'utils'
properties = __.require 'controllers', 'entities/lib/properties/properties_values_constraints'
{ yellow } = require 'chalk'

module.exports = (entity)->
  { _id, _rev, created, updated, type, redirect } = entity

  if type isnt 'entity' or redirect then return ''

  text = "inv:#{_id} a wikibase:Item ;"

  dateCreated = new Date(created).toISOString()
  text += """\n  schema:dateCreated "#{dateCreated}"^^xsd:dateTime ;"""

  dateModified = new Date(updated).toISOString()
  text += """\n  schema:dateModified "#{dateModified}"^^xsd:dateTime ;"""

  version = parseInt _rev.split('-')
  text += """\n  schema:version #{version} ;"""

  for lang, value of entity.labels
    formattedLabel = formatStringValue value
    text += """\n  rdfs:label #{formattedLabel}@#{lang} ;"""

  statementsCount = 0

  for property, propClaims of entity.claims
    statementsCount += 1
    { datatype } = properties[property]
    formatter = datatypePropClaimsFormatter[datatype]
    if formatter?
      formattedPropClaims = formatter propClaims
      text += formatPropClaims property, formattedPropClaims
    else
      console.warn yellow('missing formatter'), datatype

  text += """\n  wikibase:statements #{statementsCount} ;"""

  labelsCount = Object.keys(entity.labels).length
  # This property isn't actually used by Wikidata
  # but builds on the idea of 'wikibase:statements'
  text += """\n  wikibase:labels #{labelsCount} ;"""

  # Replace the last ';' by a '.' and add a line break
  # to have one line between each entity
  return text.replace /;$/, '.\n'

datatypePropClaimsFormatter =
  entity: _.identity
  string: (propClaims)-> propClaims.map formatStringValue
  'positive-integer': (propClaims)-> propClaims.map formatPositiveInteger
  'simple-day': (propClaims)-> propClaims.filter(validSimpleDay).map formatDate
  'image-hash': (propClaims)-> propClaims.map formatImageHash

formatStringValue = (str)->
  str = str
    # May also be of type number
    .toString()
    # Remove parts of a string that would not validate
    # ex: Alone with You (Harlequin Blaze\Made in Montana)
    .replace /\(.*\.*\)/g, ''
    # Replace any special spaces (including line breaks) by a normal space
    .replace /\s/g, ' '
    # Remove double quotes
    .replace /"/g, ''
    # Remove escape caracters
    .replace /\\/g, ''

  return '"' + _.superTrim(str) + '"'

formatPositiveInteger = (number)-> '"+' + number + '"^^xsd:decimal'
formatDate = (simpleDay)->
  sign = if simpleDay[0] is '-' then '-' else ''
  [ year, month, day ] = simpleDay.replace(/^-/, '').split('-')
  year = _.padStart year, 4, '0'
  month or= '01'
  day or= '01'
  formattedDay = "#{sign}#{year}-#{month}-#{day}"
  return '"' + formattedDay + 'T00:00:00Z"^^xsd:dateTime'

# Shouldn't be 0000-00-00 or 0000
validSimpleDay = (simpleDay)-> not /^[0-]+$/.test(simpleDay)

formatImageHash = (imageHash)-> "invimg:#{imageHash}"

formatPropClaims = (property, formattedPropClaims)->
  if formattedPropClaims.length is 0 then return ''
  """\n  #{property} #{formattedPropClaims.join(',\n    ')} ;"""
