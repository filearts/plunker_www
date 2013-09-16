{Duplex} = require 'stream'
browserChannel = require('browserchannel').server
redis = require "redis"
livedb = require 'livedb'
livedbMongo = require 'livedb-mongo'

sharejs = require 'share'



backend = livedb.client
  db: livedbMongo('localhost:27017/test?auto_reconnect', safe:false)
  redis: port: 16379, host: process.env.IP
share = sharejs.server.createClient {backend}

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
    
  rest = share.rest()
  
  webserver.use '/doc', (req, res, next) ->
    console.log "Yoink"
    rest(arguments...)