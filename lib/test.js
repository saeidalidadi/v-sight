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
    this.tests_count = 0
    this.schemas     = schemas
    this.jar         = null
    this.done        = done
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

  request_async (bodies, method, url, cb)
  {
    Async.map(bodies, (item, request_cb) => {    
      if(item.values !== undefined ) {
        const _this = this
        const data = {
          method: method,
          uri: url,
          formData: item.values,
          jar: this.jar
        }
        method == 'POST' || method == 'PUT' ? data.formData = item.values : data.qs = item.values
        Request(data, (err, response, body) => {
          if (err)
            throw(err)
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

  make_bodies_async_and_request ()
  {
    Async.mapValues(this.schemas, (item, key, cb) => {
      let schema
      if (item.query)
        schema = Joi.describe(item.query)
      else
        schema = Joi.describe(item.payload)

      const bodies  = this.make_bodies(schema, item.defaults, key)
      const parts   = _.split(key, '/')
      const method  = parts[0].toUpperCase()
      const url     = this.baseUrl + '/' + _.join(parts.slice(1),'/')

      this.request_async(bodies, method, url, cb)

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
