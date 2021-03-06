__ = require('config').universalPath
_ = __.require 'builders', 'utils'
wikidataSearch = __.require 'lib', 'wikidata/search'
requests_ = __.require 'lib', 'requests'
cache_ = __.require 'lib', 'cache'
assert_ = __.require 'utils', 'assert_types'
qs = require 'querystring'

module.exports = (query)->
  { search, refresh } = query
  assert_.string search
  key = "wd:search:#{search}"
  cache_.get { key, fn: searchEntities.bind(null, search), refresh }

searchEntities = (search)->
  search = qs.escape search
  url = wikidataSearch search
  _.log url, 'searchEntities'

  requests_.get url
  .then extractWdIds
  .then _.Success('wd ids found')

extractWdIds = (res)-> res.query.search.map _.property('title')
