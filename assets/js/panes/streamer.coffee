#= require ./../../vendor/jquery.cookie/jquery.cookie
#= require ./../../vendor/script/dist/script

#= require ./../services/participants
#= require ./../services/visitor
#= require ./../services/notifier
#= require ./../services/activity
#= require ./../services/url

#= require ./../directives/overlay


module = angular.module("plunker.panes")

module.requires.push "plunker.annotations"
module.requires.push "plunker.session"
module.requires.push "plunker.participants"
module.requires.push "plunker.visitor"
module.requires.push "plunker.notifier"
module.requires.push "plunker.activity"
module.requires.push "plunker.url"
module.requires.push "plunker.overlay"



module.run [ "$rootScope", "$q", "$location", "panes", "session", "participants", "visitor", "notifier", "activity", "url", "overlay", ($rootScope, $q, $location, panes, session, participants, visitor, notifier, activity, url, overlay) ->
  
  genid = (len = 16, prefix = "", keyspace = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789") ->
    prefix += keyspace.charAt(Math.floor(Math.random() * keyspace.length)) while len-- > 0
    prefix
    

  class VisitorState
    constructor: (streamRef, identity) ->
      state = @
      
      @identityRef = streamRef.child(identity.id)
      
      @identityRef.update identity, (err) ->
        console.log "Error setting identity", err if err
        notifier.error "Error syncing identity." if err
      
      @identityRef.on "value", (snapshot) ->
        angular.copy snapshot.val(), identity
      
      cursorRef = @identityRef.child("state")
        
      @identityRef.onDisconnect().remove()
      
      activity.client("stream").watchEvent "selection", (type, event) ->
        cursorRef.set
          buffId: event.buffId
          cursor: event.cursor
          selection: { start: event.selection.start, end: event.selection.end }
        , (err) ->
          console.log(err) if err
          notifier.error(err) if err
          
    disconnect: ->
      @identityRef.off()
      @identityRef.remove()

  class SharedState

    initialize: ->
      @initialized ||= do ->
        dfd = $q.defer()
        
        $script.get "https://cdn.firebase.com/v0/firebase.js", -> $rootScope.$apply ->
          if Firebase? then dfd.resolve new Firebase('https://plunker.firebaseIO.com/participants/')
          else dfd.reject "Unable to load Firebase"
        
        dfd.promise
    
    identify: ->
      dfd = $q.defer()
      
      if visitor.logged_in
        dfd.resolve
          id: visitor.session.public_id
          handle: visitor.user.login
          gravatar_id: visitor.user.gravatar_id
          type: "member"
      else if handle = $.cookie("plnk_stream_handle")
        dfd.resolve
          id: visitor.session.public_id
          handle: handle
          gravatar_id: visitor.session.public_id
          type: "guest"
      else
        notifier.prompt "How would you like to be identified for collaboration?", genid(4, "Guest", "0123456789"),
          confirm: (handle) ->
            $.cookie "plnk_stream_handle", handle,
              expires: 14 # 14 days from now
              path: "/edit/"
              
            dfd.resolve
              id: visitor.session.public_id
              handle: handle
              type: "guest"
          deny: -> dfd.reject()        
      
      dfd.promise
        
    connect: (id) ->
      state = @
      
      unless id.match(/^[-_a-z0-9]{1,}$/i)
        notifier.error "Invalid stream id", "Stream ids must contain only alphanumeric characters, '_' or '-'"
        return $q.reject("Invalid stream id")
      
      $q.all([@initialize(), @identify()]).then ([firebase, identity]) ->
        state.identity = identity
        state.streamRef = firebase.child(id)
        state.track(state.streamRef)
        
        state.visitor = new VisitorState(state.streamRef, identity)
      , ->
        notifier.error "You must chose a handle before using the collaboration feature."

    track: (streamRef) ->
      state = @
      
      streamRef.on "child_added", (snapshot) -> async ->
        unless snapshot.name() is state.identity.id
          angular.copy snapshot.val(), (participants[snapshot.name()] ||= {})
        
      streamRef.on "child_changed", (snapshot) -> async ->
        unless snapshot.name() is state.identity.id
          val = snapshot.val()
          
          participants[snapshot.name()][key] = value for key, value of val when key in ["handle", "id", "gravatar_id", "state"]
  
      streamRef.on "child_removed", (snapshot) -> async ->
        delete participants[snapshot.name()]
    
    disconnect: ->
      
      @streamRef.off() if @streamRef # Stop listening to all events
      
      @visitor.disconnect()
        
  async = (cb) ->
    if $rootScope.$$phase then cb()
    else $rootScope.$apply(cb)
  
  class Stream
    constructor: ->
      @id = genid(16)
      @state = null
      @streaming = false
      @doc = null
      @cleanup = []
      @type = "public"
  
    getLocalState: (type) ->
      state = session.toJSON(includeBufferId: true)
      
      defaultPerms =
        if type is "public" then read: true, write: true, admin: false
        else read: true, write: false, admin: false
      
      json =
        files: {}
        permissions:
          $default: defaultPerms
        
      json.files[buffer.id] = buffer for filename, buffer of state.files
      
      json
    
    initialize: ->
      @state ||= new SharedState
      
      $q.all [ @state.initialize(), do ->
        dfd = $q.defer()
        
        $script "#{url.collab}/js/share.js", ->
          async ->
            if sharejs? then dfd.resolve()
            else dfd.reject("Unable to load streaming code")
        
        dfd.promise
      ]
      
    connectTo: (id = uid(), type = "public") ->
      $q.reject("Invalid stream ID: #{id}") unless id.match(/^[-_a-z0-9]{1,}/i)
      
      stream = @
      
      options =
        origin: "#{url.collab}/channel"
        authentication: visitor.session.id
        
      promise = @initialize().then ->
        dfd = $q.defer()
        
        sharejs.open id, "json", options, (err, doc) -> async ->
          if err then return dfd.reject "Unable to join stream"
          
          stream.id = id
          stream.doc = doc
          stream.keep = doc.created is true and doc.version is 0
          stream.streaming = "streaming"
  
          if stream.keep
            # Reset the channel to the current local state
            doc.submitOp [ { p: [], od: doc.snapshot, oi: stream.getLocalState(type) } ], (err) ->
              if err
                doc.close()
                async -> dfd.reject("Error setting initial state")
              else
                async -> dfd.resolve(stream)
          else
            async -> dfd.resolve(stream)
      
        dfd.promise
      
      promise.then -> stream.state.connect(id)

    start: () ->
      stream = @
      client = activity.client("stream")
      
      unless stream.keep
        client.playback "reset", stream.doc.get()
        
      stream.doc.shout
        e: "connect"
        who: visitor.session.public_id
      
      stream.doc.on "shout", (event) ->
        #notifier.alert event
        console.log "SHOUT", arguments...
        
      stream.doc.on "remoteop", (ops, snapshot) ->
        for op in ops
          # Reset
          if 0 == op.p.length and op.od and op.oi then client.playback "reset", stream.doc.get()
          # Text insert and/or remove
          else if 4 == op.p.length and "files" == op.p[0] and "content" == op.p[2]
            if op.sd then client.playback "remove",
              buffId: op.p[1]
              offset: op.p[3]
              text: op.sd
            if op.si then client.playback "insert",
              buffId: op.p[1]
              offset: op.p[3]
              text: op.si
          # Rename
          else if 3 == op.p.length and "files" == op.p[0] and "filename" == op.p[2]
            if op.od and op.oi then client.playback "files.rename",
              buffId: op.p[1]
              filename: op.oi
              previous: op.od
          # Files add/remove
          else if 2 == op.p.length and "files" == op.p[0]
            if op.od then client.playback "files.remove",
              buffId: op.p[1]
            if op.oi then client.playback "files.add",
              buffId: op.p[1]
              filename: op.oi.filename
              content: op.oi.content
            
          else console.log "[ERR] Unhandled remote op", op
        
        
        
      @cleanup.push client.watchEvent "reset", (type, event) ->
        stream.doc.set(stream.getLocalState())
      
      @cleanup.push client.watchEvent "files.add", (type, json) ->
        stream.doc.submitOp
          p: ["files", json.buffId]
          oi: json
      
      @cleanup.push client.watchEvent "files.remove", (type, json) ->
        stream.doc.submitOp
          p: ["files", json.buffId]
          od: stream.doc.at(["files", json.buffId]).get()
      
      @cleanup.push client.watchEvent "files.rename", (type, json) ->
        stream.doc.submitOp
          p: ["files", json.buffId, "filename"]
          od: json.previous
          oi: json.filename
      
      @cleanup.push client.watchEvent "insert", (type, json) ->
        stream.doc.submitOp
          p: ["files", json.buffId, "content", json.offset]
          si: json.text

      @cleanup.push client.watchEvent "remove", (type, json) ->
        stream.doc.submitOp
          p: ["files", json.buffId, "content", json.offset]
          sd: json.text

    stop: ->
      while @cleanup.length
        deregister = @cleanup.pop()
        deregister()
      
      @doc.close() if @doc
      @state.disconnect() if @state
      
      # Reset (soft) the session to current state to generate new buffer ids
      activity.client("stream").playback "reset", session.toJSON()
      
      @streaming = false


  panes.add
    id: "streamer"
    icon: "retweet"
    size: 328
    title: "Collaboration"
    description: """
      Collaborate with others in real-time.
    """
    template: """
      <div class="plunker-streamer" ng-switch="stream.streaming">
        <div ng-switch-when="streaming">
          <plunker-channel ng-repeat="buffer in scratch.buffers.queue"></plunker-channel>
          <div class="status">
            <h4>Streaming enabled</h4>
            Stream: <a ng-href="{{url.www}}/edit/?p=streamer&s={{stream.id}}" target="_blank" title="Link to this stream"><code class="stream-id" ng-bind="stream.id"></code></a>
            <button class="btn btn-mini btn-danger" ng-click="stopStream()" title="Disconnect from stream">
              <i class="icon-stop"></i> Disconnect
            </button>
          </div>
          <div>
            <ul class="participants">
              <li ng-class="participant.style" ng-repeat="(public_id, participant) in participants">
                <img ng-src="http://www.gravatar.com/avatar/{{participant.gravatar_id}}?s=14&d=identicon" />
                <span ng-bind="participant.handle"></span>
              </li>
            <ul>
          </div>
        </div>
        <div ng-switch-default>
          <h3>Streaming</h3>
          <p>
            Streaming enables real-time collaboraboration on Plunker. When you
            join a stream, the contents of your editor are kept in sync with the
            stream and reflect changes made by others in the same stream.
          </p>
          <form ng-submit="startStream(stream)">
            <input class="mediumtext" ng-model="stream.id" size="32" />
            <button class="btn btn-primary" type="submit">Stream</button>
            <div>
              <label class="radio inline" title="By default, anyone can make changes">
                <input type="radio" value="public" ng-model="stream.type" />
                Public
              </label>
              <label class="radio inline" title="By default, only the stream's creator can make changes">
                <input type="radio" value="presenter" ng-model="stream.type" />
                Presenter
              </label>
            </div>
          </form>
          <h4>What happens if I hit save?</h4>
          <p>
            The current contents of your plunk will be saved as if you had
            made all the changes to the files yourstream. No one else in the stream
            will be affected at all by saving your state.
          </p>
          <h4>What happens if I load a template?</h4>
          <p>
            If you load a template, the resulting files will be sent to
            everyone else in the stream as if you had made the changes yourself.
            This is usually not what you want to do.
          </p>
        </div>
      </div>
    """
    link: ($scope, $el, attrs) ->
      pane = @
      stream = new Stream
      
      $scope.participants = participants
      $scope.stream = stream
      
      $scope.startStream = (stream) -> async ->
        overlay.show "Starting stream",
          stream.connectTo(stream.id, stream.type).then ->
            stream.start()
          , (err) -> async ->
            stream.streaming = null
            notifier.error(err)

      $scope.stopStream = ->
        stream.stop() if stream.streaming
        
      if id = $location.search().s
        stream.id = id
        stream.type = $location.search().st
        $scope.startStream(stream)
]