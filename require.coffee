# 1. make all options for request
# 2. for body array request(options, callback)
# 3. collect all responses and return
Joi = require 'joi'
Q = require 'q'
_ = require 'lodash'
validation = require './examples/validation'

missing_required = (routes) ->
  #console.log JSON.stringify routes
  deferred = Q.defer()
  payloads = []
  keys = Object.keys routes
  for k, v in keys
    payload = {}
    without_required(routes[k].payload, routes[k].defaults)
    .then (d) ->
      #console.log d
      payloads.push d
  deferred.resolve payloads
  deferred.promise

clone = (obj) ->
  return JSON.parse(JSON.stringify obj)

get_next_path = (parent, prePath, key_index) ->
  if Array.isArray(parent)
    "#{prePath}[#{key_index}]"
  else if typeof parent is 'object'
    if prePath?
      return "#{prePath}.#{key_index}"
    else
      return key_index
  else if typeof parent is 'undefined'
    return key_index

without_required = (payload, lables, defaults) ->
  payload = Joi.describe(payload)
  #console.log JSON.stringify(payload)
  deferred = Q.defer()
  final = null
  requireds = []
  notation = '$' # will be used inside path to define a value as required: '$name.$first'

  Inners = (item, parent, preKey, prePath, parentType) ->

    if item.type is 'object' and item.children?
      _.each item.children, (child, key) ->
        if preKey?
          parent[preKey] ?= {}
        nextPath = get_next_path(parent[preKey], prePath, key)
        Inners(child, parent[preKey] || parent, key, nextPath, 'object')

    else if item.type is 'alternatives'
      _.each item.alternatives, (child, key) ->
        parent[preKey] ?= []
        nextPath = get_next_path(parent[preKey], prePath, key)
        Inners(child, parent[preKey], key, nextPath, 'alternatives')

    else if item.type is 'array'
      _.each item.items, (child, key) ->
        parent[preKey] ?= []
        nextPath = get_next_path(parent[preKey], prePath, key)
        Inners(child, parent[preKey], key, nextPath, 'array')
    else
      requireds.push prePath
      parent[preKey] = item.flags.default || item.valids[0]
      true
  final = {}
  Inners(payload, final, null, null, null)
  console.log requireds
  deferred.resolve(final)
  deferred.promise

missing_required(validation::roles.user)
  .then (res) ->
    console.log res
###
without_required = (payload, lables, defaults) ->
  payload = Joi.describe(payload)
  console.log JSON.stringify(payload)
  deferred = Q.defer()
  final = null
  requireds = {}
  Inners = (item, parent, def, preKey,  parentType) ->

    if item.type is 'object' and item.children?
      _.each item.children, (child, key) ->
        if preKey?
          parent[preKey] ?= {}
        Inners(child, parent[preKey] || parent, def, key, 'object')

    else if item.type is 'alternatives'
      _.each item.alternatives, (child, key) ->
        parent[preKey] ?= []
        Inners(child, parent[preKey], def, key, 'alternatives')

    else if item.type is 'array'
      _.each item.items, (child, key) ->
        parent[preKey] ?= []
        Inners(child, parent[preKey], def, key, 'array')
    else
      parent[preKey] = item.flags.default
      final = parent
      true
  Inners(payload, {}, defaults)
  deferred.resolve(final)
  deferred.promise

###
###
#create a node for objects
create_object_node = (item, node_key) ->
  node =
    type: item.type
    next: []
  switch item.type
    when 'object'
      node.next = Object.keys(item.children)
    when 'array'
      item.items.forEach (child, key) ->
        node.next.push "#{node_key}-#{key}"
    when 'string'
      node.type = 'string'
    when 'alternatives'
      item.alternatives.forEach (child, key) ->
        if child.children?
          keys = Object.keys child.children
          for k, v in keys
            node.next.push k
        else
          node.next.push "#{node_key}-#{key}"
  node
###
flatten = (obj) ->
  #make_path(obj)
  flat_obj = {}
  #console.log JSON.stringify(payload)
  final = null
  Inners = (item, upper, def, preKey, upperKey, upperType, chains) ->
    chains ?= []
    if item.type is 'object' and item.children?
      keys = Object.keys(item.children)
      for i,v in keys
        key = keys[v].slice()
        if preKey?
          if upperKey?
            #console.log chains[chains.length-1]
            chains[chains.length-1] = chains[chains.length-1].concat(".#{upperKey}")
          else
            chains.push preKey
          upper[preKey] ?= {}
          #console.log chains, preKey
        Inners(item.children[key], upper[preKey] || upper, def, key, preKey, 'object', chains)

    else if item.type is 'alternatives'
      item.alternatives.forEach (child, key) ->
        upper[preKey] ?= []
        Inners(child, upper[preKey], def, key, preKey, 'alternatives', chains)

    else if item.type is 'array'
      #console.log preKey, upperKey
      item.items.forEach (child, key) ->
        upper[preKey] ?= []
        Inners(child, upper[preKey], def, key, preKey, 'array', chains)
    else
      upper[preKey] = item.flags.default || item.valids[0]
      final = upper
      #console.log preKey, upperType, upperKey
      #console.log final
      true
  Inners(obj, {})

