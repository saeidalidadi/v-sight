v_sight = require '../index'

vSight().flush({
  bucket: 'bucketName'
  admin: 'administrator'
  password: 'admin'
}, (result) ->
  console.log result
)
