CONFIG = require 'config'
__ = CONFIG.universalPath
_ = __.require 'builders', 'utils'
resolveEdition = require './resolve_edition'
resolveWork = require './resolve_work'
resolveAuthor = require './resolve_author'
resolveInContext = require './resolve_in_context'
resolveOnLabels = require './resolve_on_labels'
{ Promise } = __.require 'lib', 'promises'

module.exports = (entry)->
  { edition, works, authors } = entry

  Promise.resolve resolveEdition(edition)
  .then -> resolveCollection works, resolveWork
  .then -> resolveCollection authors, resolveAuthor
  .then -> resolveInContext works, authors
  .then -> resolveOnLabels works, authors
  .then -> entry

resolveCollection = (seeds, resolveSeed)-> Promise.all seeds.map(resolveSeed)
