Q               = require 'q'
Joi             = require 'joi'
_               = require 'lodash'
Missing_one     = require './delete_one'
Request         = require 'request'
Async           = require 'async'
Compare         = require './compare'

module.exports = class Validator

  testCases: [ 'missing_one']
  errors: []
  tests_count: 0
  first_error: on

  constructor: (options, @schemas, @done) ->
    @baseUrl = options.baseUrl
    @login    = if options.login? then options.login else off
    @tests_count = 0
    @errors = []
    @first_error = if options.first_error? then options.first_error else on

  call: (data, cb) =>
    _this = @
    data[0].jar = _this.jar
    Request data[0], (err, response, body) ->
      _this.tests_count--
      if err
        throw err
      message = Compare(response.statusCode, body, data[1], data[0].uri)
      if !message
          cb(false, false)
      else
        if _this.first_error
          cb(message, false)
        else
          _this.errors.push message
          cb()

  go_login: ->
    deferred = Q.defer()
    jar = Request.jar()
    Request.defaults({ jar: jar })
    Request({
      uri: "#{@baseUrl}#{@login.url}"
      method: 'POST'
      formData: @login.auth
      jar: jar
    }, (err, response, body) =>
      if err
        deferred.reject(err)
      else
        if response.statusCode isnt 200
          deferred.reject new Error "Login for #{@login.url} wasn't successfull"
      @jar = jar
      deferred.resolve(body)
    )
    deferred.promise

  missing_one_request: (loads, method, url) ->
    coll = []
    data =
      uri: "#{@baseUrl}/#{url}"
      method: method
    for i, k in loads
      if loads[k].deleted
        if method is 'POST' or method is 'PUT'
          data.formData = loads[k].values
        else
          data.qs = loads[k].values
        item = [ _.clone(data), loads[k] ]
        coll.push item
    @tests_count = @tests_count + coll.length
    Async.map coll, @call, (err, result) =>
      if @first_error
        if err
          @done(true, err)
        else @done(null, [])
      else
        if !@tests_count
          if @errors.length
            @done(true, @errors)
          else @done(null, [])

  missing_one: ->
    for key, item of @schemas
      if item.query?
        schemas = Joi.describe(item.query)
      else
        schemas = Joi.describe(item.payload)
      result  = Missing_one(schemas, item.defaults, key)
      parts   = _.split(key, '/')
      method  = parts[0].toUpperCase()
      url     = _.join(parts.slice(1),'/')
      data    =
        uri: "#{@baseUrl}/#{url}"
      switch method
        when 'POST', 'PUT'
          @missing_one_request(result, method, url)
        when 'GET'
          @missing_one_request(result, method, url)
  tests: ->
    for item, index in @testCases
      switch item
        when 'missing_one'
          @missing_one()

  run: ->
    _this = @
    if _this.login
      @go_login()
        .then (result) ->
          _this.tests()
        .catch (err) ->
          if err
            throw new Error err
        .done()
    else
      _this.tests()
