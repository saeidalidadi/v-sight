Q         = require 'q'
fs        = require 'fs'
_         = require 'lodash'
pairs     = require './pairs'
flusher   = require './flusher'
async     = require 'async'
request   = require 'request'


# validate for requireds and optionals 
  # 1. make bodies befor request
    # 1. make requireds [done]
      # 1. for all requireds we get 200
      # 2. for requireds exept one we expect to get 400 since of bad request
    # 2. add optionals to requireds so we expect to  get 200 [doing]
      # 1. iterate over optionals and add one by one
        # check for dependent and iterate over theme and add theme one by one
  # 2. iterate over bodies and post theme


internals =
  url: 'http://localhost:3100'
  form: {
    attachments: []
  }
  sample: {}
  
  getPairs: (array) ->
    Q(pairs(array, @sample))

  makeBodies: () ->
    bodies = {}
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
      @getPairs(@optionals).then (opts) ->
        bodies.o200 = []
        req = bodies.r200
        bodies.o200 = opts.map (o) ->
          req.map((r) ->
            r.slice()
          ).concat([o.slice()])
        bodies

  addFields: (pair) ->
    if pair[0][0] isnt '@'
      @form[pair[0]] = pair[1]
    else
      pair[0] = pair[0].slice 1,  pair[0].length
      @form.attachments.push { name: pair[0], path: pair[1] }

  makeForm: (body, cb) ->
    pair = body.shift()
    if _.isArray(pair)
      pair.forEach (item) =>
        @addFields(pair)
    else
      @addFields pair
    if body.length
      @makeForm(body, cb)
    else
      cb()

  makeRequest: (body, cb) ->
    @form =
      attachments: []
    @makeForm body, () =>
      attach = (attachments, cb) =>
        curr = attachments.shift()
        @form[curr.name] = fs.createReadStream(curr.path)
        if attachments.length
          attach(attachments, cb)
        else
          delete @form.attachments
          cb()

      if @form.attachments.length
        #console.log @form
        attach(@form.attachments, () =>
          #console.log @form
          request.post({url: "http://localhost:3100/v1/users/signup", formData: @form }, (err, response, data) ->
            if err
              throw err
            cb(data)
          )
        )
      else
        delete @form.attachments
        request.post({url: "http://localhost:3100/v1/users/signup", formData: @form }, (err, response, data) ->
          if err
            throw err
          cb(data)
        )

  flushData: ->
  
  checkResponse: ->

module.exports = (route, props, methods) ->
  internals.requireds = props.requireds if props?.requireds?
  internals.optionals = props.optionals if props?.optionals?
  internals.sample    = props.sample if props?.sample?
  internals.route     = route
  
  internals.makeBodies()
    .then (bodies) ->
 
      result = []

      queue = (body, bag, cb) ->
        curr = body.shift()
        Q.nfcall flusher, () ->
          internals.makeRequest(curr , (response) ->
            if body.length
              bag.push { request: curr, response: response }
              queue(body, bag, cb)
            else
              bag.push { request: curr, response: response }
              cb(bag)
          )
      ###
      queue([bodies.r200], (end) ->
        console.log 'finishe r200'
        debugger
        queue(bodies.r400, (end) ->
          console.log 'finished r400'
          debugger
          #console.log bodies.o200[0]
          queue(bodies.o200, (end) ->
            console.log 'finished o200'
          )
        )
      )
      ###
      async.series({

        r200: (cb) ->
          queue [bodies.r200], [], (bag) ->
            cb(null, "1")
            console.log '\n\n#################################### r200 #####################################\n\n'
            console.log bag

        r400: (cb) ->
          queue bodies.r400, [], (bag) ->
            console.log '\n\n#################################### r400 #####################################\n\n'
            console.log bag
            cb(null, "2")

        o200: (cb) ->
          queue bodies.o200, [], (bag) ->
            console.log '\n\n#################################### o200 #####################################\n\n'
            console.log bag
            cb(null, "3")
      
      }, (err, result) ->
        if err
          throw err
      )


  # 2.if finished response flush database
  # 3.if the response is not desired make error
  # 4.save all responses data
  # 5.go to step 1
