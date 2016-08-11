Q         = require 'q'
fs        = require 'fs'
_         = require 'lodash'
pairs     = require './lib/pairs'
flusher   = require './lib/flusher'
async     = require 'async'
request   = require 'request'
chai      = require 'chai'
assert    = chai.assert

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

  defaults: {}
  
  getPairs: (array) ->
    Q(pairs(array, @defaults))

  makeBodies: () ->
    deffered = Q.defer()
    bodies = {}
    if @requireds?
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
    if @optionals?
      @getPairs(@optionals).then (opts) ->
        bodies.o200 = []
        req = bodies.r200
        bodies.o200 = opts.map (o) ->
          req.map((r) ->
            r.slice()
          ).concat([o.slice()])
        bodies
     else
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
    # quesy is like '?var=value&var=value'
  makeRequest: (body, statusCode, cb) ->
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
          request.post({url: "#{internals.url}#{internals.route}", formData: @form }, (err, response, data) ->
            if err
              throw err
            if response?.statusCode? and response.statusCode isnt statusCode
              console.log response.statusCode
              cb(form, response)
            else
              cb(form, true)
          )
        )
      else
        form = @form
        delete @form.attachments
        request.post({url: "#{internals.url}#{internals.route}", formData: @form }, (err, response, data) ->
          if err
            throw err
          if response?.statusCode? and response.statusCode isnt statusCode
            console.log response
            cb(form, response)
          else
            cb(form, true)
        )


  checkStatus: (response, status) ->
    deffered = Q.defer()
    if response?.statusCode? and response.statusCode isnt status
      console.log response.statusCode
      deffered.resolve(false)
      assert.equal(response.statusCode, status)
    else
      deffered.resolve(true)
    deffered.promise



module.exports = (options) ->
  
  internals.url = if options?.url? then options.url else 'http://localhost'
  
  {
    flush: (db, cb) ->
      db = if db then db else options.db
      flusher db, cb
    look: (route, props) ->
      deffered = Q.defer()
      internals.requireds = props.requireds if props?.requireds?
      internals.optionals = props.optionals if props?.optionals?
      internals.defaults  = props.defaults if props?.defaults?
      internals.route     = route
      
      internals.makeBodies()
        .then (bodies) ->
          queue = (body, statusCode, bag, cb) ->
            curr = body.shift()
            Q.nfcall flusher, options.flusher, () ->
              internals.makeRequest(curr , statusCode, (request, response) ->
                bag.push { request: request, response: response }
                if body.length
                  queue(body, statusCode,bag, cb)
                else
                  cb(bag)
              )

          async.series({

             r200: (cb) ->
               if internals.requireds?
                 queue [bodies.r200], 200, [], (bag) ->
                   cb(null, bag)
               else
                 cb(null, true)

             r400: (cb) ->
               if internals.requireds?
                 queue bodies.r400, 400, [], (bag) ->
                   cb(null, bag)

             o200: (cb) ->
               if internals.optionals?
                 queue bodies.o200, 200, [], (bag) ->
                   cb(null, bag)
               else
                 cb(null, true)
            
          }, (err, result) ->
            if err
              throw err

            deffered.resolve(result)
            if options.log?
              console.log '\n\n#################################### r200 #####################################\n\n'
              console.log result.r200[0].response.body
              console.log '\n\n#################################### r400 #####################################\n\n'
              console.log result.r400[0].response.body
              console.log '\n\n#################################### o200 #####################################\n\n'
              console.log result.o200[0].response.body
          )
          deffered.promise
  }
