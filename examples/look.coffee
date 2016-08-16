vSight = require('../index.js')
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
  reception_avatar: "#{__dirname}/images/avatar.jpg"
  policy:         "This is our policy"
  image_files:    [ "#{__dirname}/images/hostel1.jpg", "#{__dirname}/images/hostel2.jpg" ]

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
# Post without authentication
# user signup
describe 'signup a user', ->
  @.timeout(5000)
  it '01 should return true', (done)->
    validations =
      requireds: ['name:ali','@avatar', 'email', 'device:ios', 'version:2' ]
      optionals: [ "interests", 'info[address][city]' ]
      defaults: USER

    look('POST', '/v1/users/signup', validations)
      .then (result) ->
        console.log result.o200
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
          headers: res.headers
          defaults: HOSTEL
        look('POST', '/v1/admin/hostels', validations)
          .then (res) ->
            console.log res

# Get with authentication
#   admin gets hostels list
#   /v1/admin/hostels
describe 'get hostel', ->
  it '04should return hostels', ->
    admin_agent.get('/v1/admin/hostels')
      .then (res) ->
        console.log res.body
  it '05 should validate queries', (done) ->
    login_admin()
      .then (res) ->
        validations =
          optionals: [ 'state:new', 'state:approved']
          headers: res.headers
        look('GET', '/v1/admin/hostel', validations)
          .then (res) ->
            console.log res
            done()

# Put with authentication
#   hostel update profile
#   /v1/dashboard/me
describe 'update profile', ->
  it '04 should return success after profile update', ->
    login_hostel()
      .then (res) ->
        hostel_agent.put('/v1/dashboard/me')
        .field( 'name', 'new name')
        .then (res) ->
          console.log res.body

# Delete with authentication
# hostel delete an image of activity
# /v1/dashboard/me/images/{image_name}
