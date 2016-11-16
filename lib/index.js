'use strict'

const Validator = require ('./test')

const internals = {
  baseUrl: 'http://localhost'
}

const root = {}

root.defaults = function (options) {
  internals.baseUrl = options.baseUrl
  internals.testCases = ['missing_one', 'fake_property']
}

root.look = function (options, schemas, done) {

  options.baseUrl = options.baseUrl !== undefined ? options.baseUrl : internals.baseUrl
  const validator = new Validator(options, schemas, done)
  return validator.run()
}

module.exports = root
