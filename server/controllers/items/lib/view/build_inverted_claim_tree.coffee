base = ->
  author: {}
  genre: {}
  subject: {}

viewProperties =
  'wdt:P50': 'author'
  'wdt:P136': 'genre'
  'wdt:P921': 'subject'

addToTree = (tree, entity)->
  { uri, claims } = entity
  for property, name of viewProperties
    values = entity.claims[property]
    if values?
      for value in values
        tree[name][value] or= []
        tree[name][value].push uri
    else
      tree[name].unknown or= []
      tree[name].unknown.push uri

  return tree

module.exports = (entities)-> entities.reduce addToTree, base()
