browserchannel = require "../../vendor/share/bcsocket-uncompressed.js"
require "../../vendor/share/share.uncompressed.js"

require "../services/session.coffee"


module = angular.module "plunker.service.collab", [
  "plunker.service.session"
]

module.factory "collab", [ "$rootScope", "$q", "session", ($rootScope, $q, session) ->
  console.log "Browserchannel", browserchannel
  
  socket = browserchannel.BCSocket(null, {reconnect: true})
  share = new window.sharejs.Connection(socket)
  client = session.createClient("share")

  connect: (sessionId) ->
    dfd = $q.defer()
    doc = share.getOrCreate("json_test", sessionId)
    
    doc.subscribe()
    
    doc.whenReady -> $rootScope.$apply -> 
      unless doc.type
        doc.create "json0", snapshot = client.getSnapshot(), ->
          dfd.resolve snapshot
      else
        client.reset snapshot = doc.getSnapshot()
        dfd.resolve snapshot
        
      client.on "remoteOp", (e) ->
        
        doc.submitOp e.op
        
    doc.on "op", (op) ->
      unless $rootScope.$$phase then $rootScope.$apply ->
        console.log "Remoteop", arguments...
        client._applyOps(op)
    
    dfd.promise
    

]