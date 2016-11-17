'use strict'

const create_error = function (testCase, status_code, body, flag, url, key) {
  return function(help) {
    return {
      code: status_code,
      url: url,
      server_message: body,
      flag: flag,
      testCase: testCase,
      property: key,
      help: help
    }
  }
}

exports.create_error = create_error
