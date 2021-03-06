# A module to look for works labels occurrences in an author's external databases reference.

__ = require('config').universalPath
_ = __.require 'builders', 'utils'
promises_ = __.require 'lib', 'promises'
error_ = __.require 'lib', 'error/error'
assert_ = __.require 'utils', 'assert_types'
getWikipediaArticle = __.require 'data', 'wikipedia/get_article'
getBnfAuthorWorksTitles = __.require 'data', 'bnf/get_bnf_author_works_titles'
getOlAuthorWorksTitles = __.require 'data', 'openlibrary/get_ol_author_works_titles'
getEntityByUri = __.require 'controllers', 'entities/lib/get_entity_by_uri'

# - worksLabels: labels from works of an author suspected
#   to be the same as the wdAuthorUri author
# - worksLabelsLangs: those labels language, indicating which Wikipedia editions
#   should be checked
module.exports = (wdAuthorUri, worksLabels, worksLabelsLangs)->
  assert_.string wdAuthorUri
  assert_.strings worksLabels
  assert_.strings worksLabelsLangs

  # get Wikipedia article title from URI
  getEntityByUri { uri: wdAuthorUri }
  .then (authorEntity)->
    # Known case: entities tagged as 'missing' or 'meta'
    unless authorEntity.sitelinks? then return []

    promises_.all [
      getWikipediaOccurrences authorEntity, worksLabels, worksLabelsLangs
      getBnfOccurrences authorEntity, worksLabels
      getOpenLibraryOccurrences authorEntity, worksLabels
    ]
  .then _.flatten
  .then _.compact
  .catch (err)->
    _.error err, 'has works labels occurrence err'
    return []

getWikipediaOccurrences = (authorEntity, worksLabels, worksLabelsLangs)->
  promises_.all getMostRelevantWikipediaArticles(authorEntity, worksLabelsLangs)
  .map createOccurrences(worksLabels)

getMostRelevantWikipediaArticles = (authorEntity, worksLabelsLangs)->
  { sitelinks, originalLang } = authorEntity

  return _.uniq worksLabelsLangs.concat([ originalLang, 'en' ])
  .map (lang)->
    title = sitelinks["#{lang}wiki"]
    if title? then return { lang, title }
  .filter _.identity
  .map getWikipediaArticle

getAndCreateOccurencesFromIds = (prop, getWorkTitlesFn)-> (authorEntity, worksLabels)->
  ids = authorEntity.claims[prop]
  # Discard entities with several ids as one of the two
  # is wrong and we can't know which
  if ids?.length isnt 1 then return false
  getWorkTitlesFn ids[0]
  .filter (doc)-> _.includes worksLabels, doc.quotation
  .map createOccurrences(worksLabels)

getBnfOccurrences = getAndCreateOccurencesFromIds 'wdt:P268', getBnfAuthorWorksTitles
getOpenLibraryOccurrences = getAndCreateOccurencesFromIds 'wdt:P648', getOlAuthorWorksTitles

createOccurrences = (worksLabels)->
  worksLabelsPattern = new RegExp(worksLabels.join('|'), 'gi')
  return (article)->
    matchedTitles = _.uniq article.quotation.match(worksLabelsPattern)
    unless matchedTitles.length > 0 then return false
    return { url: article.url, matchedTitles }
