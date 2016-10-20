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
  promises = []
  for k, v in keys
    payload = {}
    promises.push without_required(routes[k].payload, routes[k].defaults)
  Q.all(promises).then (result) ->
    deferred.resolve result
  deferred.promise

clone = (obj) ->
  return JSON.parse(JSON.stringify obj)

split_and_sign = (prePath, index) ->
  tmp = prePath.split('.')
  tmp[tmp.length-1] = "$#{tmp[tmp.length-1].slice()}"
  return tmp.join('.')

get_next_path = (parent, prePath, key_index, child) ->
  if Array.isArray(parent)
    if child?.flags?.presence is 'required'
      prePath = split_and_sign(prePath)
      return  "#{prePath}[#{key_index}]"
    return "#{prePath}[#{key_index}]"
  else if typeof parent is 'object'
    if prePath?
      if child?.flags?.presence is 'required'
        return "#{prePath}.$#{key_index}"
      return "#{prePath}.#{key_index}"
    else
      return key_index
  else
    if child?.flags?.presence is 'required'
      return "$#{key_index}"
    return key_index

without_required = (payload, defaults) ->
  payload = Joi.describe(payload)
  #console.log JSON.stringify(payload)
  deferred = Q.defer()
  final = null
  all_path = []
  notation = '$' # will be used inside path to define a value as required: '$name.$first'
  errors = []
  Inners = (item, parent, preKey, prePath, parentType) ->

    if item.type is 'object' and item.children?
      _.each item.children, (child, key) ->
        if preKey?
          parent[preKey] ?= {}
        nextPath = get_next_path(parent[preKey], prePath, key, child)
        #requireds.push nextPath
        Inners(child, parent[preKey] || parent, key, nextPath, 'object')

    else if item.type is 'alternatives'
      _.each item.alternatives, (child, key) ->
        parent[preKey] ?= []
        nextPath = get_next_path(parent[preKey], prePath, key, child)
        Inners(child, parent[preKey], key, nextPath, 'alternatives')

    else if item.type is 'array'
      _.each item.items, (child, key) ->
        parent[preKey] ?= []
        nextPath = get_next_path(parent[preKey], prePath, key, child)
        Inners(child, parent[preKey], key, nextPath, 'array')
    else
      all_path.push prePath
      if item.flags?.default?
        parent[preKey] = item.flags.default
      else
        for_search = _.replace(prePath, '$','')
        parent[preKey] = _.get(defaults, for_search)
        if typeof parent[preKey] is 'undefined'
          errors.push for_search

  final = {}
  console.log final
  Inners(payload, final, null, null, null)
  if errors.length
    deferred.reject(errors)
  else
    deferred.resolve({ values: final, paths: all_path, errors: errors})
  console.log all_path
  console.log final
  deferred.promise

missing_required(validation::roles.user)
  .then (res) ->
    #console.log res

