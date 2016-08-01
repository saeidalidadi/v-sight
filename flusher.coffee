couchbase = require('couchbase')
cluster = new couchbase.Cluster('couchbase://127.0.0.1')
bucket = cluster.openBucket("tipi")
exec = require('child_process').execFile

module.exports = (done) ->
  
  user = 'Administrator:rootroot'
  header = 'Content-Type: application/json'
  query = '?stale=false&inclusive_end=true&connection_timeout=6000&skip=0&reduce=false'
  url = "http://localhost:8092/tipi/_design/dev_flusher/_view/get_all#{query}"
  
  exec("curl", [ '-X', 'GET', '-u', user, '-H', header, url ], (err, out, code) =>
    body = JSON.parse(out)
    body = body.rows
    if body.length is 0
      done()
    else
      remove = (body) ->
        curr = body.shift()
        bucket.remove(curr.id, (result) ->
          if body.length then remove(body) else done()
        )
      remove(body, (result) ->
        #done()
      )
      true
  )
