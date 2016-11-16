### Installation
```
sudo npm install v-sight
```
### How it works
It uses `Joi schema` signature for API schemas as input and will check for test cases by making suited payloads or queries and will return result that contains unexpected responses from API calls for each route as below:

### Examples and usage
This module supports these test cases already:
* `missing_one`: All properties except one will be sent in request and the response status code shoud be `400` if missed one is `required` and should not be `400` if it is one of `optionals` .
* `fake_property`: All properties added one fake property which response should be `400`.

### Returned errors structure
All fialed tests have this structure when:
```javascript
{
  status_code: 'http status codes',
  url: 'baseUrl + route',
  flag: 'from schema or fake for fake_property test case',
  server_message: 'returning message from server',
  help: 'a message will help you to find the error'
}

```javascript
v_sight = require('v-sight')

// Setting defaults
v_sight.defaults({ baseUrl: 'http://localhost:8080' })

// Setting options for a role
var user_options = {
  login: {
    url: '/v1/users/login',
    auth: {
      email: 'john.doue@mail.me',
      password: 'test-password-1',
    }
  }
}

// User signup validations
user_schemas = {
  'post/v1/users/buy': {
    payload: {
      product_id: Joi.string().required(),
      description: Joi.string().optional(),
      address: Joi.object().keys({
        City: Joi.string().required().default('Tehran'),
        Street: Joi.string().required()
      }
    },
    defaults: {
      product_id: '1234',
      description: 'This is my desired one',
      address: {
        Street: 'Motahari'
      }
    }
  }
}

v_sight.look(user_Options, user_schemas, (errors) => {
  if(errors) {
    console.log(errors)
  }
})

```
#### Use with `Mocha` and `chai`
When using mocha you can call `done()` in callback:
```javascript
var should = require('chai').should();

describe('Users', () => {
  it('should be validate for all requireds, optinals'), function(done) {
    v_sight.look(user_Options, user_schemas, (errors) => {
      should.not.exist(errors)
      done()
    })
});
```
