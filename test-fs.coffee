fs = require 'fs'
request = require 'request'
flusher = require './flusher'
async = require 'async'
eye = require './eye'

n = 100

forms = []
Q = require 'q'


USER =
  name: 'John Connor'
  email: 'john.connor@gmail.com'
  avatar: "#{__dirname}/images/avatar.jpg"
  passport:
    scan: "#{__dirname}/images/scan.jpg"
    number: 333333
  version: 1
  device: 'android'
  city: 'Sydny'
  gender: 'male'

props =
  optionals: [ 'city', 'gender:male', ['passport[number]', 'passport[scan]:323999' ] ]
  requireds: ['email', 'name', 'version', 'device', '@avatar']
  sample: USER

#eye('/va/users/signup', props)

addForms = () ->
  while n > 0
    forms.push({
      email: 'john.conner@mail.com'
      device: 'android'
      version: 2
      name: 'saeid'
    })
    --n
  forms

done = () ->
  console.log 'flushed'

addRequest = (forms) ->
  len = forms.length
  curr = forms.shift()
  curr.avatar = fs.createReadStream '/home/SAlidadi/Projects/tipi/users/test/functional/images/avatar.jpg'

  Q.nfcall flusher, () ->
    request.post({ url: "http://localhost:3100/v1/users/signup", formData: curr }, (err, response, body) ->
      if forms.length then addRequest(forms) else  'ok'
    )
  

Q addForms()
  .then (forms) ->
    console.log forms
    addRequest(forms)
