
'use strict'

const _ = require('lodash')

//will count all Nodes
const count_nodes = function (obj) {
  let count = 0
  count++
  for(let key in obj.children) {
    count  = count + count_nodes(obj.children[key])
  }
  return count
}

// @param {Object} obj - object to delete properties one by one
// @return all created payloads or queries within an object as bellow:
//  { deleted: path, values: { path_key: value, ... }, schema: schema_object }
const delete_one = function (obj, defaults) {

  let deleted = false
  const createds = []
  const Delete = function (Node, container, pre_path ) {
    if(Node.deleted == undefined && !deleted) {
      Node.deleted = true
      deleted = true
      container.schema = Node
      container.deleted = pre_path
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

  const count = count_nodes(obj)
  for(let i=0; i < count; i++) {
    let result = Delete(obj, {})
    createds.push(result)
    deleted = false
  }

  return createds
}

module.exports = delete_one
