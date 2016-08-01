eye = require './eye'

USER =
  name: 'John Connor'
  email: 'john.connor@gmail.com'
  avatar: "#{__dirname}/eye.jpg"
  passport:
    scan: "#{__dirname}/eye.jpg"
    number: 333333
  version: 1
  device: 'android'
  city: 'Sydny'
  gender: 'male'

props =
  optionals: [ 'city', 'gender:male', ['passport[number]:333333', 'passport[scan]' ] ]
  requireds: ['email', 'name', 'version', 'device', '@avatar']
  sample: USER

eye('/va/users/signup', props)

