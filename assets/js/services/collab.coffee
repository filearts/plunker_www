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
    console.log "Share", share
    
    dfd = $q.defer()
    doc = share.get("json_test", sessionId)
    
    doc.subscribe()
    
    doc.whenReady (args...) ->
      console.log "Document ready", arguments...
      $rootScope.$apply -> 
        unless doc.type
          console.log "Document does not exist, creating", client.getSnapshot()
          doc.create "json0", snapshot = client.getSnapshot(), ->
            dfd.resolve snapshot
        else unless doc.snapshot
          op =
            p: []
            od: doc.snapshot
            oi: client.getSnapshot()
  
          console.log "Document exists but is false, resetting", doc, op
          
          doc.submitOp op, -> dfd.resolve doc.snapshot
        else
          console.log "Got snapshot", doc, doc.getSnapshot()
          
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