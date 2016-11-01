validation = require './validation'
vSight = require '../lib/index'

vSight.defaults({ baseUrl: 'http://localhost:3100' })

userOptions =
  login:
    url: '/v1/users/login'
    auth:
      device: 'ios'
      email: 'saeid@mail.me'
      version: 'v2.2'
      auth: 'c3e94e76-660a-4b4d-b733-399a43b498a1'

hostelOptions =
  login:
    url: '/v1/dashboard/login'
    auth:
      email: 'hostel@mail.com'
      password: '12345678'
###
describe 'user validations', ->
  it 'should be validated for missing required', (done) ->
    vSight.run(userOptions, validation::roles.user, (errors) ->
      console.log errors
      done()
    )
    #done()
###
done = (err, result) ->
  console.log err
  console.log 'sssssss'
vSight.run(userOptions, validation::roles.user, done)

###
vSight.run(hostelOptions, validation::roles.hostel)
	.then (result) ->
		console.log result
###
###
signup_callback = (err, res, body) ->
  if err
    console.log err
  body = JSON.parse body
  console.log body
  auth = body.data?.auth || 'c3e94e76-660a-4b4d-b733-399a43b498a1'
  request({
    uri: 'http://localhost:3100/v1/users/login'
    method: 'POST'
    formData:
      email: 'saeid@mail.me'
      device: 'ios'
      version: 'v2.2'
      auth: auth
  }, login_callback)

request({
  uri: 'http://localhost:3100/v1/users/signup'
  method: 'POST'
  formData:
    name: 'Saeid'
    email: 'saeid@mail.me'
    version: 'v2.2'
    device: 'ios'
    avatar: fs.createReadStream(__dirname + '/examples/eye.jpg')
}, signup_callback)
###
