'use strict'

const _ = require('lodash')
const Helper = require('./helper')
const FakeProperty = require('./fake_property')

const internals = {}

internals.FakePostQuery = class extends FakeProperty
{

  constructor (options, schemas, done)
  {
    super(options, schemas, done);
    this.fake_key   = 'fake_post_query';
    this.test_name  = 'fake_post_query';
    this.fake_value = 'ThisIsAFakePostQuery';
  }

  compare (status_code, body, item, url, cb)
  {
    const body_object = JSON.parse(body)
    const create_error = Helper.create_error(this.test_name, status_code, body_object, this.flag, url, item.target_path)
    let message = null
    if(status_code == 400) {

      message = internals.code_400(body, item.target_path)

    } else {

      message = internals.other_codes(body, item.target_path)

    }

    message ? cb(null, create_error(message)) : cb(null, message)
  }

  make_bodies (obj, defaults, method)
  {
    if(method != undefined && method == 'POST') {
      const container =  this.create_values(obj, defaults)
      return [container]

    }
  }

  create_data (body, schema_key)
  {
    const method_url = this.generate_method_url(schema_key)
    const data = {
          qs: this.add_fake_qs(),
          method: method_url[0].slice(),
          uri: method_url[1].slice(),
          jar: this.jar,
          timeout: this.timeout
    }
    return this.add_qs_formData(data, body)
  }

  add_fake_qs()
  {
      const fake_key = this.fake_key
      return { fake_key: this.fake_value }
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

module.exports = internals.FakePostQuery
