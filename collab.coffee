{Duplex} = require 'stream'
browserChannel = require('browserchannel').server
redis = require "redis"
livedb = require 'livedb'
livedbMongo = require 'livedb-mongo'
nconf = require "nconf"

sharejs = require 'share'

console.log "[INFO] Connecting to Redis: ", nconf.get("db:redis:port"), nconf.get("db:redis:host"), auth_pass: nconf.get("db:redis:pass")

redisClient = redis.createClient(nconf.get("db:redis:port"), nconf.get("db:redis:host"), auth_pass: nconf.get("db:redis:pass"))
redisObserverClient = redis.createClient(nconf.get("db:redis:port"), nconf.get("db:redis:host"), auth_pass: nconf.get("db:redis:pass"))

backend = livedb.client
  db: livedbMongo(nconf.get("db:mongodb"), safe:false)
  redis: redisClient
  redisObserver: redisObserverClient
share = sharejs.server.createClient {backend}


onRedisError = -> console.log "[ERR] Redis error", arguments...

redisClient.on "error", onRedisError
redisObserverClient.on "error", onRedisError

exports.extend = (webserver) ->
  webserver.use browserChannel {webserver}, (client) ->
    stream = new Duplex objectMode:yes
    stream._write = (chunk, encoding, callback) ->
      console.log 's->c ', chunk
      if client.state isnt 'closed' # silently drop messages after the session is closed
        client.send chunk
      callback()
  
    stream._read = -> # Ignore. You can't control the information, man!
  
    stream.headers = client.headers
    stream.remoteAddress = stream.address
  
    client.on 'message', (data) ->
      console.log 'c->s ', data
      stream.push data
  
    stream.on 'error', (msg) ->
      client.stop()
  
    client.on 'close', (reason) ->
      stream.emit 'close'
      stream.emit 'end'
      stream.end()
  
    # ... and give the stream to ShareJS.
    share.listen stream
    
