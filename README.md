### Installation
```
sudo npm install v-sight
```

### Adding flusher view to views in `Couchbase`.
We use flusher for `post` method in npm. So before validations for `post` method you should add bellow view to your `caouchbase`.
1.  Go to **views** tab and click on `Create Development View`
and insert bellows in fields:

```
Design Document Name:

_design/dev_flusher 

View Name:
get_all
```

2.  Click on `edit` and add bellow function to **map**:

```
function(doc) {emit(null, null)}
```
### Using Curl to add view
Also you have an command line alternative to set view in couchbase
```
curl -X PUT -u [admin]:[password] -H "Content-Type: application/json" 'http://127.0.0.1:8092/[bucket-name]/_design/dev_flusher' -d '{"language": "javascript"}'
curl -X PUT -u [admin]:[password] -H "Content-Type: application/json" 'http://127.0.0.1:8092/[bucket-name]/_design/dev_flusher' -d '{"views":{"get_all":{"map":"function(doc){emit(null,null)}"}}}'
```
for more informations look at this [couchbase reference](http://docs.couchbase.com/admin/admin/REST/rest-ddocs-create.html)
### Examples and usage
We have three points for validations:
* `r200`: All requireds will send in request an the response status code shoud be `200`.
* `r400`: All requireds exept one will send in request and the response status code should be `400`.
* `o200`: All optionals will send one by one so all response status code shoud be `200`.
for valid response we will return true in response that is a property for reults array
and for invalids will return response object in response property of a point that itself is a property of an object.

```javascript
v_sight = require('v-sight')

var options = {
  url: 'http://localhost:8080'
  flusher: {
    bucket: 'bucketName'
    admin: 'admin'
    password: 'admin'
  }
}

look = v_sight(options).look
var USER = {
  name: 'John'
  password: 'password'
  address: { country: 'Iran' }
  avatar: __dirname + '/avatar.jpg'
}
// User signup validations
validations = {
  requireds: [ 'email', 'password' ] // if you won't define in defaults use property:value
  optionals: [ 'address[city]:Tehran', 'addres[country]', '@avatar' ]// for attachments use @
  defaults: USER
  headers: { cookie: 'sid' }
}

look('POST', '/users/signup', vaidations)
.then(function(result) {
  if (result.all)
    console.log('passed all validations test')
  else
    console.log(result) // where response is object you shoud see the body
})
```
### flusher
You can use npm internal flusher if need flushing as bellow:
```javascript
db = {
  bucket: 'bucketName'
  admin: 'admin'
  password: 'admin'
}

flush = v_sight().flush
flush( db, (err) => {
  if(err)
    throw err;
  else
    console.log('flushed');
})
```
#### Use with `Mocha`
When using mocha pass done() callback to `flusher` like :
```javascript
afterEach(function(done) {
  flusher(db , done)
});

it('should be validate for all requireds, optinals, requireds exept one'), function() {
  // do validations test
});
```
For more on how to use please look at `examples`.
