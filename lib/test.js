'use strict'

const Joi               = require ('joi')
const _                 = require ('lodash')
const Request           = require ('request')
const Async             = require ('async')

// To remove node.js warning for limitted eventListeners
require('events').EventEmitter.defaultMaxListeners = Infinity

const internals = {}

internals.Test = class
{
  constructor (options, schemas, done)
  {
    this.baseUrl     = options.baseUrl
    this.login       = options.login !== undefined ? options.login : false
    this.errors      = []
    this.first_error = options.first_error !== undefined ? options.first_error : true
    this.schemas     = schemas
    this.jar         = null
    this.done        = done
    this.timeout     = options.timeout !== undefined ? options.timeout : 3000
  };

  go_login (cb)
  {
    const _this = this
    let jar = Request.jar()
    Request.defaults({ jar: jar })
    Request({
      uri: this.baseUrl + this.login.url,
      method: 'POST',
      formData: this.login.auth,
      jar: jar,
    }, (err, response, body) => {
      if (err)
        throw(err)
      else if (response.statusCode !== 200)
          return cb( new Error("Login for " + _this.login.url + "wasn't successfull") )
      this.jar = jar
      cb(null)
    })
  }

  add_qs_formData (data, body)
  {
      data.method == 'POST' || data.method == 'PUT' ? data.formData = body : data.qs = body;
      return data
  }

  create_data (body, schema_key)
  {
    const method_url = this.generate_method_url(schema_key)
    const data = {
          method: method_url[0].slice(),
          uri: method_url[1].slice(),
          jar: this.jar,
          timeout: this.timeout
    }
    return this.add_qs_formData(data, body)
  }

  request_async_and_compare (bodies, schema_key, cb)
  {
    Async.map(bodies, (item, request_cb) => {
      if(item.values !== undefined ) {
        const data = this.create_data(item.values, schema_key)
        Request(data, (err, response, body) => {
          if (err) {
            throw new Error(err.code + ' after request to ' + data.uri)
          }
          const url = this.generate_method_url(schema_key)[1].slice()
          this.compare(response.statusCode, body, item, url, (err, message) => {
            if(this.first_error && message) {
              request_cb(message)
            } else {
              request_cb(null, message)
            }
          });
        });
      } else {
       request_cb(null, '')
      }
    }, (err, result) => {
      if(err) {
        cb(err)
      } else {
        const cleaned = internals.remove_empty(result)
        cb(null, cleaned)
      }
    })
  }

  generate_method_url (schema_key)
  {
    const parts   = _.split(schema_key, '/')
    const method  = parts[0].toUpperCase()
    const url     = this.baseUrl + '/' + _.join(parts.slice(1),'/')
    return [method, url]
  }

  make_bodies_async_and_request ()
  {
    Async.mapValues(this.schemas, (item, key, cb) => {
      let schema
      if (item.query)
        schema = Joi.describe(item.query)
      else
        schema = Joi.describe(item.payload)
      const method = this.generate_method_url(key)[0]
      const bodies = this.make_bodies(schema, item.defaults, method)
      if(bodies) {

        this.request_async_and_compare(bodies, key, cb)

      } else {

        cb(null, [])
      }

    }, (err, result) => {
 
        if(err) {
          this.done(err)
        } else {
          const errors = internals.remove_empty(result)
          _.isEmpty(errors) ? this.done(null) : this.done(errors)
        }
    })
  }

  run ()
  {
    const _this = this
    if (this.login)
      this.go_login( (err, result) => {
        _this.make_bodies_async_and_request()
      })
    else
      _this.make_bodies_async_and_request()
  }
}

internals.remove_empty = function (coll) {
  if(_.isArray(coll))
    return _.compact(coll)
  return _.pickBy(coll, (item, index) => {
    if(item.length) return item
  })
}

module.exports = internals.Test
