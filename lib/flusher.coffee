couchbase = require('couchbase')
cluster = new couchbase.Cluster('couchbase://127.0.0.1')
exec = require('child_process').execFile
bucket = null
module.exports = (options, done) ->
  
  if(!bucket)
    bucket = cluster.openBucket("#{options.bucket}")
  
  user = "#{options.admin}:#{options.password}"
  header = 'Content-Type: application/json'
  query = '?stale=false&inclusive_end=true&connection_timeout=6000&skip=0&reduce=false'
  url = "http://localhost:8092/#{options.bucket}/_design/dev_flusher/_view/get_all#{query}"
  
  exec("curl", [ '-X', 'GET', '-u', user, '-H', header, url ], (err, out, code) =>
    if err
      console.log err
    body = JSON.parse(out)
    body = body.rows
    if body?.length is 0
      done()
    else
      remove = (body) ->
        curr = body.shift()
        bucket.remove(curr.id, (result) ->
          if body.length then remove(body) else done()
        )
      remove(body)
      true
  )
