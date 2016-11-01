'use strict'

const _ = require('lodash')

const get_presence = function(schema) {
  if(schema.flags !== undefined && schema.flags.presence !== undefined) {
    return schema.flags.presence
  }
  else
    return 'optional'
}

// we got 400
const missing_400 = function(body, removed_path, presence, url) {

  let message = false
  const body_object = JSON.parse(body)
  const index = _.findIndex(body_object.validation.keys, (item) => item == removed_path)
  
  if(presence == 'required' && index !== -1) {
    return message = false
  }
  else if(presence == 'required') { 
    return message = '"' + url + '": '
                     + 'We got 400 by deletion of "' 
                     + removed_path + 
                     '"but got this bad request with another messaage as: "'
                     + body_object.message + '"'
  }
  else if(presence == 'optional' && index !== -1) {
    return message = '"' + url + '": '
                     + 'We got 400 by deletion of "' 
                     + removed_path + 
                     '" that is an optional property in your schema"'
  }
  else
    console.log('optional - not equal')
  return message
}

// we didn't get 400
const missing_others = function(body, removed_path, presence, url) {

  let message
  const body_object = JSON.parse(body)
  let index = -1
  if(body_object.validation !== undefined)
    index = _.findIndex(body_object.validation.keys, (item) => item == removed_path)
  if(presence == 'required') {
    return message = '"' + url + '"' +
                     "We didn't got 400 for deletion of " + '"'
                      + removed_path + 
                      '" that is a required property in your schema "' 
  }
  if(presence == 'optional')
    return message = false

}

// map to functions for status codes
const missing_compare = function(statuse_code, body, removed_one, url) {
  const presence = get_presence(removed_one.schema)
  if(statuse_code == 400){
    return missing_400(body, removed_one.deleted.dot, presence, url)
  }
  else return missing_others(body, removed_one.deleted.dot, presence, url)
}

module.exports = missing_compare
