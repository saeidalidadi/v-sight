### Installation
```
sudo npm install v-sight
```
### How it works
It uses `Joi schema` signature for API schemas as input and will check for test cases by making suited payloads or queries and will return result that contains unexpected responses from API calls.

### Examples and usage
The npm supports these test cases already:
* `missing_one`: All properties except one will be sent in request and the response status code shoud be `400` if missed one is `required` and should not be `400` if it is one of `optionals` .

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

v_sight.look(user_Options, user_schemas, (err , result) => {
  if(err)
   throw err
  else
    if(result.length)
      console.log(result)
})
```
#### Use with `Mocha`
When using mocha pass call `done()` in callback:
```javascript
describe('Users', () => {
  it('should be validate for all requireds, optinals'), function(done) {
    v_sight.look(user_Options, user_schemas, (err , result) => {
      err.should.be.equal('false')
      result.length.should.be.equal(0)
      done()
    })
});
```
For more on how to use please look at `examples`.
