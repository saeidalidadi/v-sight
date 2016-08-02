eye = require './index.js'
chai     = require 'chai'
should   = chai.should()
Q = require 'q'

USER =
  name: 'John Connor'
  email: 'john.connor@gmail.com'
  avatar: "#{__dirname}/eye.jpg"
  passport:
    scan: "#{__dirname}/eye.jpg"
    number: '333333'
  version: 1
  device: 'android'
  city: 'Shiraz'
  gender: '1'

props =
  optionals: [ 'city', 'gender:1', ["passport[number]:ddddddddd", '@passport[scan]' ] ]
  requireds: ['email', 'name', 'version', 'device', '@avatar']
  defaults: USER

loo = eye({
  log: true
  url: 'http://localhost:8080'
  flusher:
    bucket: 'tipi'
    admin:'Administrator'
    password: 'rootroot'
})

describe "Guys", ->
  it 'should look at me after signup', (done) ->
    @.timeout 7000
    loo.look('/v1/users/signup', props, (result) ->
      #console.log result
      done()
    )

