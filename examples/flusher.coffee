v_sight = require '../index'

v_sight().flush({
  bucket: 'tipi'
  admin: 'Administrator'
  password: 'rootroot'
}, (result) ->
  console.log 'flushed'
  process.exit()
)
