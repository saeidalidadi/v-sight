Q         = require 'q'
fs        = require 'fs'
_         = require 'lodash'
pairs     = require './lib/pairs'
flusher   = require './lib/flusher'
async     = require 'async'
request   = require 'request'

# validate for requireds and optionals [done]
  # 1. make bodies befor request [done]
    # 1. make requireds [done]
      # 1. for all requireds we get 200 [done]
      # 2. for requireds exept one we expect to get 400 since of bad request [done]
    # 2. add optionals to requireds so we expect to  get 200 [done]
      # 1. iterate over optionals and add one by one [done]
        # check for dependent and iterate over theme and add theme one by one [done]
  # 2. iterate over bodies and post theme [done]

internals =
  url: 'http://localhost'
  form: {
    attachments: []
  }
  all: true
  requireds: []
  optionals: []
  defaults: {}
  getPairs: (array) ->
    Q(pairs(array, @defaults))

  makeBodies: () ->
    deffered = Q.defer()
    bodies = {}
    if @requireds.length
      @getPairs(@requireds).then (result) =>
        bodies.r200 = result
        bodies.r400 = []
        temp = result
        len = temp.length
        
        while len > 0
          po = _.without(temp, temp[len-1])
          bodies.r400.push po
          temp = result
          len--
    if @optionals.length
      @getPairs(@optionals).then (opts) ->
        bodies.o200 = []
        req = bodies?.r200 ? []
        if req.length != 0
          bodies.o200 = opts.map (o) ->
            req.map((r) ->
              r.slice()
            ).concat([o.slice()])
        else
          bodies.o200 = ([o] for o in opts)
    deffered.resolve(bodies)
    deffered.promise

  addFields: (pair) ->
    if pair[0][0] isnt '@'
      @form[pair[0]] = pair[1]
    else
      temp = pair[0].slice 1,  pair[0].length
      @form.attachments.push { name: temp, path: pair[1] }

  makeForm: (body, cb) ->
    pair = body.shift()
    if _.isArray(pair[0])
      pair.forEach (item) =>
        @addFields(item)
    else
      @addFields pair
    if body.length
      @makeForm(body, cb)
    else
      cb()

  makeQuery: (body) ->
    deffered = Q.defer()
    query = '?'
    body.forEach (pair) ->
      query = "#{query}#{pair[0]}=#{pair[1]}&"
    deffered.resolve query
    deffered.promise
    # quesy is like '?var=value&var=value'
  makeRequest: (body, statusCode, cb) ->
    switch @method
      when 'post' then @post(body, statusCode, cb)
      when 'get'  then @get(body, statusCode, cb)
      when 'put'  then @put(body, statusCode, cb)
      else
        console.log 'Not found any method, please set your method'

  post: (body, statusCode, cb) ->
    @form =
      attachments: []
    @makeForm body, () =>
      attach = (attachments, cb) =>
        curr = attachments.shift()
        if attachments.length
          @form[curr.name] = fs.createReadStream(curr.path)
          attach(attachments, cb)
        else
          @form[curr.name] = fs.createReadStream(curr.path)
          delete @form.attachments
          cb()

      if @form.attachments.length
        form = @form
        attach(@form.attachments, () =>
          if @method is 'post'
            @agent.post({url: "#{internals.url}#{internals.route}", formData: @form, headers: @headers}, (err, response, data) =>
              if err
                throw err
              if response?.statusCode? and response.statusCode isnt statusCode
                @all = false
                cb(form, response)
              else
                cb(form, true)
            )
          else
            @agent.put({url: "#{internals.url}#{internals.route}", formData: @form, headers: @headers}, (err, response, data) =>
              if err
                throw err
              if response?.statusCode? and response.statusCode isnt statusCode
                @all = false
                cb(form, response)
              else
                cb(form, true)
            )
          )
      else
        form = @form
        delete @form.attachments
        if @method is 'post'
          @agent.post({url: "#{internals.url}#{internals.route}", formData: @form, headers: @headers }, (err, response, data) =>
            if err
              throw err
            if response?.statusCode? and response.statusCode isnt statusCode
              @all = false
              cb(form, response)
            else
              cb(form, true)
          )
        else
          @agent.put({url: "#{internals.url}#{internals.route}", formData: @form, headers: @headers }, (err, response, data) =>
            if err
              throw err
            if response?.statusCode? and response.statusCode isnt statusCode
              @all = false
              cb(form, response)
            else
              cb(form, true)
          )

  get: (body, statusCode, cb) ->
    @makeQuery(body)
      .then (result) =>
        @agent.get "#{@url}#{@route}#{result}", (err, response, data) =>
            if response?.statusCode? and response.statusCode isnt statusCode
              @all = false
              cb(result, response)
            else
              cb(result, true)

  put: (body, statusCode, cb) ->
    @post(body, statusCode, cb)
  checkStatus: (response, status) ->
    deffered = Q.defer()
    if response?.statusCode? and response.statusCode isnt status
      deffered.resolve(false)
      assert.equal(response.statusCode, status)
    else
      deffered.resolve(true)
    deffered.promise
  reset: ->
    @requireds = []
    @optionals = []
    @all = true

module.exports = (options) ->
  internals.url = if options?.url? then options.url else 'http://localhost'
  {
    flush: (db, cb) ->
      db = if db then db else options.db
      flusher db, cb
    look: (method, route, props) ->
      deffered = Q.defer()
      internals.method    = method.toLowerCase()
      internals.requireds = props.requireds if props?.requireds?
      internals.optionals = props.optionals if props?.optionals?
      internals.defaults  = props.defaults if props?.defaults?
      internals.route     = route
      internals.headers   = if props.headers then props.headers else {}
      internals.headers.connection = 'keep-alive'
      internals.agent     = request
      internals.makeBodies()
        .then (bodies) ->
          queue = (body, statusCode, bag, cb) ->
            curr = body.shift()
            if internals.method is 'post'
              Q.nfcall flusher, options.flusher, () ->
                internals.makeRequest(curr , statusCode, (request, response) ->
                  bag.push { request: request, response: response }
                  if body.length
                    queue(body, statusCode,bag, cb)
                  else
                    cb(bag)
                )
            else
              internals.makeRequest(curr , statusCode, (request, response) ->
                bag.push { request: request, response: response }
                if body.length
                  queue(body, statusCode,bag, cb)
                else
                  cb(bag)
              )

          async.series({
             r200: (cb) ->
               if internals.requireds.length
                 queue [bodies.r200], 200, [], (bag) ->
                   cb(null, bag)
               else
                 cb(null, true)
             r400: (cb) ->
               if internals.requireds.length
                 queue bodies.r400, 400, [], (bag) ->
                   cb(null, bag)
               else
                 cb(null, true)
             o200: (cb) ->
               if internals.optionals.length
                 queue bodies.o200, 200, [], (bag) ->
                   cb(null, bag)
               else
                 cb(null, true)
          }, (err, result) ->
            if err
              throw err
            result.all = internals.all
            deffered.resolve(result)
            internals.reset()
          )
          deffered.promise
  }
