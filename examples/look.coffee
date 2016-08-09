vSight = require('../index')


defaults =
  email: 'testmail@mail.com'
  password: 'password'
  device: 'android'
  avatar: "#{__dirname}/eye.jpg"
  info:
    address:
      country: 'IRAN'
      city: 'Tehran'

config =
  url: 'localhost:8080'
  flusher:
    bucket: 'bucketName'
    admin: 'administrator'
    password: 'admin'

validations =
  requireds: [ 'email', 'password', 'device:ios' ]
  optionals: [ '@avatar', 'info[address][city]' ]
  defaults: defaults

vSight(config).look('/users/signup', validations, (result) ->
  console.log result
)

