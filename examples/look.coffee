vSight = require('../index')
chai = require 'chai'
should = chai.should()
chaiHttp = require 'chai-http'

chai.use chaiHttp

USER =
  email: 'testmail@mail.com'
  password: '12345678'
  device: 'android'
  avatar: "#{__dirname}/eye.jpg"
  version: 2.2
  interests: ['sss','sssaaaa']
  info:
    address:
      country: 'IRAN'
      city: 'Tehran'

HOSTEL =
  email:          "hostel@tipi.me"
  password:       "12345678"
  booking_apis:   ["booking.com", "agoda"]
  name:           "Backpacker Heaven"
  description:    "We love backpackers"
  location:
    latitude:     33.8688
    longitude:    151.2093
  country:        "Australia"
  city:           "Sydney"
  city_code:      "sydney"
  address:        "Kings Cross, Sydney 2000"
  phone:          "+61 2200 3000"
  reception_name: "Jason K."
  reception_avatar: "#{__dirname}/eye.jpg"
  policy:         "This is our policy"
  image_files:    [ "#{__dirname}/eye.jpg", "#{__dirname}/eye.jpg" ]

URL = 'http://localhost:3100'
config =
  url: URL
  flusher:
    bucket: 'tipi'
    admin: 'Administrator'
    password: 'rootroot'

admin_agent = chai.request.agent(URL)
hostel_agent= chai.request.agent(URL)

login_admin = ->
  admin_agent
  .post('/v1/admin/login')
  .send( email: 'admin', password: 'adminadmin' )
  .then (res) ->
    res

create_hostel = (hostel)->
  admin_agent
    .post('/v1/admin/hostels')
    .field('name', hostel?.name ? HOSTEL.name)
    .field('email', hostel?.email ? HOSTEL.email)
    .field('password', hostel?.password ? HOSTEL.password)
    .field('country', hostel?.country ? HOSTEL.country)
    .field('city', hostel?.city ? HOSTEL.city)
    .then (res) ->
      res.should.have.status 200
      if !hostel
        HOSTEL.key = res.body.data.doc_key
      res

login_hostel = (credentials) ->
  hostel_agent.post('/v1/dashboard/login')
    .field('email', credentials?.email ? HOSTEL.email )
    .field( 'password', credentials?.password ? HOSTEL.password )
    .then (res) ->
      res.should.have.status 200
      res

look = vSight(config).look
flusher = vSight(config).flush
afterEach (done) ->
  flusher config.flusher, done
# Post without authentication
# user signup
describe 'signup a user', ->
  @.timeout(15000)
  it '01 should return true', (done)->
    validations =
      requireds: ['name:ali','@avatar', 'email', 'device:ios', 'version:2' ]
      optionals: [ "interests", 'info[address][city]' ]
      defaults: USER

    look('POST', '/v1/users/signup', validations)
      .then (result) ->
        console.log result
        done()

# Post with authentication
# admin creats hostel
# /v1/admin/hostels
describe 'create hostel', ->
  it '02 should create a hostel', ->
    login_admin()
      .then (res) ->
        create_hostel()
      .then (res) ->
        console.log res.headers
  it '03 should validate hostel creation', ->
    login_admin()
      .then (res) ->
        validations =
          requireds: ['name', 'email', 'password', 'country', 'city']
          optionals: ['description']
          headers:
            cookie: res.headers['set-cookie'][0].split(';',1)[0]
          defaults: HOSTEL
        look('POST', '/v1/admin/hostels', validations)
          .then (res) ->
            console.log res

# Get with authentication
#   admin gets hostels list
#   /v1/admin/hostels
describe 'get hostel', ->
  it '04 should return hostels', ->
    admin_agent.get('/v1/admin/hostels')
      .then (res) ->
  it '05 should validate queries', (done) ->
    login_admin()
      .then (res) ->
        validations =
          requireds: [ 'state:new', 'state:approved']
          headers: res.headers['set-cookie'][0].split(';', 1)[0]
          defaults: USER
        look('GET', '/v1/admin/hostel', validations)
          .then (result) ->
            console.log result
            done()

# Put with authentication
#   hostel update profile
#   /v1/dashboard/me
describe 'update profile', ->
  it '06 should return success after profile update', ->
    login_admin()
      .then (res) ->
        create_hostel()
      .then (res) ->
        login_hostel()
      .then (ress) ->
        cookie =  ress.headers['set-cookie'][0]
        cookie =  cookie.split(';')
        validations =
          optionals: ['name', 'address']
          defaults: HOSTEL
          headers:
            cookie: cookie[0]
        look('PUT','/v1/dashboard/me', validations)
          .then (result) ->
            console.log result.o200
        ###
        hostel_agent.put('/v1/dashboard/me')
        .field( 'name', 'new name')
        .then (res) ->
          console.log res.body
        ###
# Delete with authentication
# hostel delete an image of activity
# /v1/dashboard/me/images/{image_name}
