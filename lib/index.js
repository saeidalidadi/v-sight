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
  let options         = _.isArray(args[1]) ? internals : args[1]
  options             = (typeof options == 'function') ? internals : options

  let testCases       = args.length == 4 ? args[2] : options.testCases
  testCases           = testCases == undefined ? internals.testCases : testCases

  options.baseUrl     = options.baseUrl == undefined ? internals.baseUrl : options.baseUrl

  const done          = (typeof args[args.length - 1] == 'function') ? args[args.length-1] : false

  if (!done)
    throw new Error('callback is not defined')

  if (options.first_error !== undefined && !options.first_error) {

    internals.all(testCases, options, schemas, done)

  } else {

    Async.each(testCases, (item, cb) => {

      const testClass = ( new (require('./' + item) )(options, schemas, (err) => {
        cb(err)
      })).run()

    }, (err) => {
      done(err)
    })
  }
}

internals.all = function (testCases, options, schemas, done) {

  Async.map(testCases, (testCase, cb) => {

    ( new (require('./' + testCase) )(options, schemas, (errors) => {
      cb(null, errors)
    })).run()

  }, (err, result) => {

    result = internals.merge_result(result)
    done(result)

  })
}

internals.merge_result = function (result) {

  return _.reduce(result, (last, curr) => {

    return _.mergeWith(last, curr, (des, src) => {

      if (_.isArray(des)) {
        return des.concat(src);
      }
    })
  }, {})
}

module.exports = root
