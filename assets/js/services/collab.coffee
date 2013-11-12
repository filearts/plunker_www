browserchannel = require "../../vendor/share/bcsocket-uncompressed.js"
sharejs = require "share/lib/client"

require "../services/session.coffee"


module = angular.module "plunker.service.collab", [
  "plunker.service.session"
]

module.factory "collab", [ "$rootScope", "$q", "session", ($rootScope, $q, session) ->
  console.log "Browserchannel", browserchannel
  
  socket = browserchannel.BCSocket(null, {reconnect: true})
  share = new sharejs.Connection(socket)
  client = session.createClient("share")

  connecting: false
  sessionId: null
  connect: (@sessionId) ->
    dfd = $q.defer()
    collab = @
    doc = share.get("json_test", @sessionId)
    
    doc.subscribe()
    
    doc.whenReady (args...) ->
      console.log "[OK] Subscribed to stream", collab.sessionId, doc
      $rootScope.$apply -> 
        unless doc.type
          console.log "[OK] Document does not exist, creating", doc, client.getSnapshot()
          doc.create "json0", snapshot = client.getSnapshot(), ->
            dfd.resolve snapshot
        else unless doc.snapshot
          op =
            p: []
            od: doc.snapshot
            oi: client.getSnapshot()
  
          console.log "[OK] Document exists but is false, resetting", doc, client.getSnapshot()
          
          doc.submitOp op, -> dfd.resolve doc.snapshot
        else
          console.log "[OK] Got snapshot", doc, doc.getSnapshot()
          
          client.reset snapshot = doc.getSnapshot()
          dfd.resolve snapshot
          
        client.on "remoteOp", (e) ->
          
          doc.submitOp e.op
        
    doc.on "op", (op) ->
      unless $rootScope.$$phase then $rootScope.$apply ->
        client._applyOps(op)

    doc.on "after op", (op) ->
      unless angular.equals(stream = doc.getSnapshot(), local = client.getSnapshot())
        console.log "[ERR] Session out of sync", local, stream

        
    @connecting = dfd.promise
    

]