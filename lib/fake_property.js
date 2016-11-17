'use strict'

const _ = require('lodash')
const Helper = require('./helper')
const Test = require('./test')
const internals = {
  test: 'fake_property',
  flag: 'fake'
}

internals.FakeProperty = class extends Test
{
  constructor (options, schemas, done)
  {
    super(options, schemas, done);
    this.fake_key = 'fake_property';
    this.test_name = this.fake_key;
    this.flag = 'fake';
    this.fake_value = 'ThisIsAFakeProperty';
  }

  compare (status_code, body, item, url, cb)
  {
    const body_object = JSON.parse(body)
    const create_error = Helper.create_error(this.test_name, status_code, body_object, this.flag, item.target_path, url)
    let message = null
    if(status_code == 400) {

      message = internals.code_400(body, item.target_path, url)

    } else {

      message = internals.other_codes(body, item.target_path, url)
    }

    message ? cb(null, create_error(message)) : cb(null, message)
  }
  
  add_fake (container)
  {
    container.values[this.fake_key] = 'ThisIsAFakeProperty'
    container.target_path = this.fake_key
    return [container]
  }
  // will add a fake property to root of payload and query
  // @param {obj} - the schema to mine the requireds from
  // @param {defaults} - the object which contains default values
  // @retuen {Object} - an object which contains values an added fake property
  create_values(obj, defaults)
  {
    const container = { values: {} , schema: obj, target_path: this.fake_key }

    const Deep = function (Node, pre_path) {
      if(Node.children !== undefined) {
        _.each(Node.children, (item, key) => {
          const next_path = pre_path == undefined ? key : pre_path + '[' + key + ']'
          Deep(item, next_path)
        })
      } else {
        let value = undefined
        if(Node.flags !== undefined) {
          value = Node.flags.default !== undefined ? Node.flags.default : _.get(defaults, pre_path)
        } else {
          value = _.get(defaults, pre_path)
        }
        if(!value)
          throw ('Not defined value for "' + pre_path.dot + '" payload or query')
        container.values[pre_path] = value
      }
    }

    Deep(obj)
    return container
  }

  make_bodies (obj, defaults)
  {
    const container = this.create_values(obj, defaults)
    return this.add_fake(container)
  }
}

internals.code_400 = function(body, fake_path) {

  let message = ''
  let index = -1
  if (body.validation !== undefined) {
    index = _.findIndex(body.validation.keys, (item) => item == '.' + fake_path)
  }
  if (index == -1) {
    return message
  } else {
    message = 'Is not from this fake property'
  }
  return message
}

// we didn't get 400
internals.other_codes = function(fake_path) {

  let message = ''
  return message = 'Fake properties are allowed for this URL'
}

module.exports = internals.FakeProperty
