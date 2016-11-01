Validator = require './validator'

internals =
  baseUrl: 'http://localhost'

root = {}

root.defaults = (options) ->
  internals.baseUrl = options.baseUrl

root.look = (options, schemas, done) ->
  options.baseUrl = if options.baseUrl? then options.baseUrl else internals.baseUrl
  validator = new Validator(options, schemas, done)
  return validator.run()

module.exports = root
