'use strict'

const Async = require('async')
const _= require('lodash')

const internals = {
  baseUrl: 'http://localhost',
  testCases: ['missing_one', 'fake_property', 'fake_post_query']
}

const root = {}

root.defaults = function (options) {
  internals.baseUrl   = options.baseUrl
  internals.testCases = options.testCases == undefined ? internals.testCases : options.testCases
}

root.look = function (schemas /* options, testCases, done*/ ) {

  const args          = arguments
  const options       = _.isArray(args[1]) ? internals : args[1]
  const case_options  = (typeof options == 'function') ? internals : options

  let testCases       = args.length == 4 ? args[2] : case_options.testCases
  testCases           = testCases == undefined ? internals.testCases : testCases

  case_options.baseUrl= case_options.baseUrl == undefined ? internals.baseUrl : case_options.baseUrl

  const done          = (typeof args[args.length - 1] == 'function') ? args[args.length-1] : false

  if(!done)
    throw new Error('callback is not defined')

  Async.each(testCases, (item, cb) => {

    const testClass = ( new (require('./' + item) )(options, schemas, (err) => {
      cb(err)
    })).run()

  }, (err) => {
    done(err)
  })
}

module.exports = root
