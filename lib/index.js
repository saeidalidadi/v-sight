'use strict'

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
  console.log('options')
  const missing_one = new (require('./missing_one'))(options, schemas, done)
  missing_one.run()
  const fake_property = new (require('./fake_property'))(options, schemas, done)
  fake_property.run()

}

module.exports = root
