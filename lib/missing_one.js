'use strict'

const _      = require('lodash')
const Helper = require('./helper')
const Test   = require('./test')

const internals = {}

internals.MissingOne = class extends Test
{
  constructor (options, schema, done) {
    super(options, schema, done)
    this.name = 'missing_one'
  }
  //will compare response and with desired of test case
  compare (status_code, body, removed_one, url, cb)
  {
    let message        = null
    const key          = removed_one.target_path.dot
    const presence     = internals.get_presence(removed_one.schema)
    const body_object  = JSON.parse(body)
    const create_error = Helper.create_error('missing_one', status_code, body_object, presence, url, key)
    
    if(status_code == 400){
    
      message = internals.code_400(body_object, presence, key)
    
    } else {

      message =  internals.other_codes(status_code, body_object, presence, key)
    }
    
    message ? cb(null, create_error(message)) : cb(null, message)
  }

  /* @param {Object} obj - object to delete properties one by one
  /* @return all created payloads or queries within an object as bellow:
  /* { deleted: path, values: { path_key: value, ... }, schema: schema_object }
  */
  make_bodies (obj, defaults) {

    let deleted = false
    const createds = []
    const Delete = function (Node, container, pre_path ) {
      if(Node.deleted == undefined && !deleted) {
        Node.deleted = true
        deleted = true
        container.schema = Node
        container.target_path = pre_path
        if(container.target_path !== undefined && container.values == undefined)
          container.values = {}
        return container
      }
      const keys = Node.children !== undefined ? Object.keys(Node.children) : []
      if (keys.length) {

        for(let i = 0; i < keys.length; i++) {
          const key = keys[i]
          let next_path = ''
          if (pre_path !== undefined) {

            next_path = { bracket: pre_path.bracket + '[' + key + ']', dot: pre_path.dot + '.' + key }
          }
          else {
            next_path = { dot: key, bracket: key }
          }
          Delete(Node.children[key], container, next_path)
        }
      }
      else {
        container.values = container.values == undefined ? {} : container.values
        let value = undefined
        if(Node.flags !== undefined) {
          value = Node.flags.default !== undefined ? Node.flags.default : _.get(defaults, pre_path.bracket)
        }
        else
          value = _.get(defaults, pre_path.bracket)

        if(!value)
          throw ('Not defined value for "' + pre_path.dot + '" payload or query')

        return container.values[pre_path.bracket] = value
      }
      return container
    }

    const count = internals.count_nodes(obj)
    for(let i=0; i < count; i++) {
      let result = Delete(obj, {})
      createds.push(result)
      deleted = false
    }

    return createds
  }
}

internals.count_nodes = function (obj) {
  
  function counter(obj) {
    let count = 0
    count++
    for(let key in obj.children) {
      count  = count + counter(obj.children[key])
    }
    return count
  }
  return counter(obj)
}

internals.get_presence = function(schema) {
  if(schema.flags !== undefined && schema.flags.presence !== undefined) {
    return schema.flags.presence
  }
  else
    return 'optional'
}

// we got 400
internals.code_400 = function(body, presence, removed_path) {
  
  let message = ''
  if(body.validation == undefined)
    return message
  const index = _.findIndex(body.validation.keys, (item) => item == removed_path)
  
  if (presence == 'required' && index !== -1) {
    
    return message
  
  } else if (presence == 'required') {

    message = 'Maybe is not for this required property'
  
  } else if (presence == 'optional' && index !== -1) {
    
    message = 'Maybe the property is not optional for this URL'
  
  } else {
    message = 'Maybe is not for this optional deletion'
  }

  return message
}

// we didn't get 400
internals.other_codes = function(status_code, body, presence, removed_path) {

  let message = ''
  let index = -1
  
  if (body.validation !== undefined)
    index = _.findIndex(body.validation.keys, (item) => item == removed_path)
  
  if (status_code == 401) {
  
    message = 'Maybe for incorrct URL'
  
  } else if (presence == 'required') {

    message = 'Maybe the property is optional for this URL' 
  
  } else if(presence == 'optional')
      message = ''
  
  return message
}

module.exports = internals.MissingOne
