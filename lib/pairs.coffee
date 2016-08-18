_ = require 'lodash'
Q = require 'q'

internals = {}

# array signature: [ 'field_1', 'field_2:value_2', ['field_3[any]', 'field_4[other]:2020'] ] 
# get one item by iterate over the array


# split : to find values
splitter = (item) ->
  if item.indexOf(':') isnt -1
    if item.indexOf('[') isnt -1
      splits = item.split(':')
    else
      splits = item.split(':')
  else
    false

# define nesteds like some[value] so we can get value from sample if is not here
getValue = (st, obj) ->
  try
    st.replace(/\[([^\]]+)]/g, '.$1').split('.').reduce (o, p) ->
      o[p]
    , obj
  catch err
    console.log err

# check that the item first index is @
###
hasAtsign = (item) ->
  if item.indexOf('@') isnt -1
    console.log 'ooooops'
    true
###

getPairs = (item) ->
  val = splitter(item)
  if val isnt off
    val
  else
    if item.indexOf('[') isnt -1
      if item.indexOf('@') isnt -1
        cleanItem = item.slice 1,  item.length
      [ item, getValue(cleanItem || item, internals.source) ]
    else
      if item.indexOf('@') isnt -1
        cleanItem = item.slice 1,  item.length
      [ item, internals.source[cleanItem || item] ]

# return as [ [ item, value ], [ item, value ], ... ]
module.exports = (array, source) ->
  internals.source = source
  pairs = _.map array, (item) ->
    if _.isArray item
      _.map item, (nested) ->
        getPairs(nested)
    else
      getPairs(item)
