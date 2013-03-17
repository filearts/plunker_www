#= require ./../services/plunks
#= require ./../services/notifier
#= require ./../services/activity

module = angular.module "plunker.session", [
  "plunker.plunks"
  "plunker.notifier"
  "plunker.activity"
]

module.service "session", [ "$rootScope", "$q", "$timeout", "plunks", "notifier", "activity", ($rootScope, $q, $timeout, plunks, notifier, activity) ->

  genid = (len = 16, prefix = "", keyspace = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789") ->
    prefix += keyspace.charAt(Math.floor(Math.random() * keyspace.length)) while len-- > 0
    prefix
    
  valueAtPath = (obj, path = []) ->
    path = [path] if path and not angular.isArray(path)
    
    return obj unless path.length
    return obj unless obj?
    
    ref = obj
    
    for seg in path
      ref = ref[seg]
      
      return ref unless ref?
    
    return ref

  new class Session
    $$cleanState = {}
    $$savedState = {}
    $$history = []
  
    $$counter = 0
  
    $$uid = genid.bind(null, 16, "__")
  
    $$asyncOp = (operation, fn) ->
      dfd = $q.defer()
  
      fn.call(@, dfd)
  
      dfd.promise.then ->
        @loading = ""
      , ->
        @loading = ""
  
    constructor: ->
      @plunk = null
      @source = ""
  
      @loading = ""
  
      @description = ""
      @tags = []
      @private = true
  
      @buffers = {}
      
      if state = window.localStorage.getItem("plnkr_dirty_exit")
        try
          @lastSession = JSON.parse(state)
        catch e
          console.log "[ERR] Invalid saved state."
  
      @reset()
      
      
      client = activity.client("session")
      session = @
      
      client.handleEvent "reset", (type, event) -> session.reset(event, soft: true)
      client.handleEvent "files.add", (type, event) -> $rootScope.$apply ->
        session.addBuffer(event.filename, event.content, id: event.buffId)
      client.handleEvent "files.remove", (type, event) -> $rootScope.$apply ->
        if buffer = session.buffers[event.buffId]
          session.removeBuffer(buffer.filename)
      client.handleEvent "files.rename", (type, event) -> $rootScope.$apply ->
        if buffer = session.buffers[event.buffId]
          session.renameBuffer(buffer.filename, event.filename)
      
      window.onbeforeunload = =>
        if @isDirty() then "You have unsaved work on this Plunk."
        
      setInterval ->
        if session.isDirty() then window.localStorage.setItem("plnkr_dirty_exit", JSON.stringify(session.toJSON(includeSource: true, includePlunk: true)))
        else window.localStorage.removeItem("plnkr_dirty_exit")
      , 1000
    
    isSaved: -> !!@plunk and @plunk.isSaved()
    isWritable: -> !!@plunk and @plunk.isWritable()

    isPlunkDirty: (path, state) ->
      previous = valueAtPath(state or $$savedState, path)
      current = valueAtPath(@toJSON(raw: true), path)
      
      return !angular.equals(previous, current)

    isDirty: (path, state) ->
      previous = valueAtPath(state or $$cleanState, path)
      current = valueAtPath(@toJSON(raw: true), path)
      
      return !angular.equals(previous, current)
  
    getActiveBuffer: ->
      throw new Error("Attempting return the active buffer while the Session is out of sync") unless $$history.length
  
      buffId = $$history[0]
      buffer = @buffers[buffId]
  
    getBufferByFilename: (filename) ->
      test = (against) ->
        if filename.test then filename.test(against)
        else filename == against
        
      for buffId, buffer of @buffers
        if test(buffer.filename)
          return buffer
  
      return
    
    getEditPath: ->
      if @plunk then @plunk.id or ""
      else @source or ""
    
    toJSON: (options = {}) ->
      if options.raw
        json =
          description: @description
          tags: @tags
          private: @private
          buffers: angular.copy(@buffers)
          source: angular.copy(@source)
      
        buffer.content = "" for buffId, buffer of json.buffers if options.dirtyContent
        
        json
      else
        json =
          description: @description
          tags: @tags
          'private': @private
          files: {}
    
        for buffId, buffer of @buffers
          json.files[buffer.filename] =
            filename: buffer.filename
            content: if options.dirtyContent then "" else buffer.content
          json.files[buffer.filename].id = buffId if options.includeBufferId
      
        json.source = angular.copy(@source) if options.includeSource
        json.plunk = angular.copy(@plunk) if options.includePlunk
    
      json
  
    reset: (json = {}, options = {}) ->
      $$savedState = {}
      
      @$resetting = true
      
      unless options.soft
        @plunk = null
        @plunk = plunks.findOrCreate(json.plunk) if json.plunk
        
        @source = json.source or ""
  
      @description = json.description or ""
      @tags = json.tags or []
      @private = !!json.plunk?.private or !!json.private
      
      @removeBuffer(buffer) for buffId, buffer of @buffers
      
      @addBuffer(file.filename, file.content, {id: file.id, activate: true}) for filename, file of json.files if json.files
      @addBuffer("index.html", "") unless $$history.length
  
      @activateBuffer(buffer) if buffer = @getBufferByFilename(/^index\./i)

      @skipDirtyCheck = true if options.dirty
      
      activity.client("session").record "reset", @toJSON(includeBufferId: true)
      
      $$cleanState = @toJSON(raw: true, dirtyContent: options.dirty)
      $$savedState = @toJSON(raw: true) if @plunk?.isSaved()

      @$resetting = false

      @
  
    open: (source) ->
      unless source then return notifier.warning """
        Open cancelled: No source provided.
      """.trim()
  
      self = @
  
      $$asyncOp.call @, "open", (dfd) ->
        importer.import(source).then (json) ->
          self.reset(json)
  
          dfd.resolve(self)
        , (err) ->
          dfd.reject(err)
          notifier.error """
            Open failed: #{err}
          """.trim()
    
  
    save: (options = {}) ->
      if @plunk and not @plunk.isWritable() then return notifier.warning """
        Save cancelled: You do not have permission to change this plunk.
      """.trim()
      
      self = @
      
      update = (plunk) =>
        lastCleanState = angular.copy($$savedState)
        inFlightState = @toJSON(raw: true)
        
        json = {}
      
        if @isDirty("description") then json.description = @description 
        
        if @isDirty("tags")
          json.tags = {}
          
          # Mark all previous tags for deletion
          for tag in lastCleanState.tags
            json.tags[tag] = null
            
          for tag in @tags
            json.tags[tag] = true
          
        if @isDirty("buffers")
          json.files = {}
          
          # Here there is the challenge that someone renames a file from
          # A to B and then creates a file named A. The file delta should show
          # a change of contents of A to match B's contents and a creation of
          # B with A's contents.
                    
          # Step 1: recognize any file deletions
          for buffId, prev of lastCleanState.buffers when not @buffers[buffId]
            json.files[prev.filename] = null
            
          # Step 2: recognize updates to all existing files
          for buffId, buffer of inFlightState.buffers when @isDirty(["buffers", buffId])
            if prev = lastCleanState.buffers[buffId]
              json.files[prev.filename] = {}
              json.files[prev.filename].filename = buffer.filename unless prev.filename is buffer.filename
              json.files[prev.filename].content = buffer.content unless prev.content is buffer.content
          
          # Step 3: recognise all new files
          for buffId, buffer of inFlightState.buffers when @isDirty(["buffers", buffId])
            unless lastCleanState.buffers[buffId]
              if renameConflict = json.files[buffer.filename]
                # Adjust the existing rename to become a new file
                json.files[renameConflict.filename] = content: renameConflict.content
                
              # Create the new file
              json.files[buffer.filename] = content: buffer.content
        
        json = angular.extend json, options

        $$asyncOp.call @, "save", (dfd) ->
          plunk.save(json).then (plunk) ->
            $$cleanState = angular.copy(inFlightState)
            $$savedState = angular.copy(inFlightState)
            notifier.success "Plunk updated"
            dfd.resolve(self)
          , (err) ->
            dfd.reject(err)
            notifier.error """
              Save failed: #{err}
            """.trim()

      create = (plunk) =>
        lastCleanState = angular.copy($$savedState)
        inFlightState = @toJSON(raw: true)
      
        json = angular.extend @toJSON(), options
        
        $$asyncOp.call @, "save", (dfd) ->
          plunk.save(json).then (plunk) ->
            $$cleanState = angular.copy(inFlightState)
            $$savedState = angular.copy(inFlightState)
            self.plunk = plunk
            notifier.success "Plunk created"
            dfd.resolve(self)
          , (err) ->
            dfd.reject(err)
            notifier.error """
              Save failed: #{err}
            """.trim()
            
      if @plunk?.isSaved() then update(@plunk)
      else create(@plunk || plunks.findOrCreate())
  
    fork: (options = {}) ->
      unless @plunk?.isSaved() then return notifier.warning """
        Fork cancelled: You cannot fork a plunk that does not exist.
      """.trim()
  
      json = angular.extend @toJSON(), options
      self = @
      
      inFlightState = @toJSON(raw: true)
      
      $$asyncOp.call @, "fork", (dfd) ->
        plunks.fork(self.plunk, json).then (plunk) ->
          self.plunk = plunk
          $$cleanState = angular.copy(inFlightState)
          $$savedState = angular.copy(inFlightState)
  
          notifier.success "Plunk forked"
  
          dfd.resolve(self)
        , (err) ->
          dfd.reject(err)
  
          notifier.error """
            Fork failed: #{err}
          """.trim()
  
    destroy: ->
      unless @plunk.isSaved() then return notifier.warning """
        Delete cancelled: You cannot delete a plunk that is not saved.
      """.trim()
  
      self = @
  
      $$asyncOp.call @, "destroy", (dfd) ->
        @plunk.destroy().then ->
          self.reset()
  
          notifier.success "Plunk deleted"
  
          dfd.resolve(self)
        , (err) ->
          dfd.reject(err)
  
          notifier.error """
            Delete failed: #{err}
          """.trim()
  
  
    addBuffer: (filename, content = "", options = {}) ->
      if @getBufferByFilename(filename) then return notifier.warning """
        File not added: A file named '#{filename}' already exists.
      """.trim()
      
      buffId = options.id or $$uid()
      
      @buffers[buffId] =
        id: buffId
        filename: filename
        content: content
        participants: {}
  
      $$history.push(buffId)
      
      unless @$resetting then activity.client("session").record "files.add",
        buffId: buffId
        filename: filename
        content: content
  
      @activateBuffer(filename) if options.activate is true
  
      @
  
    removeBuffer: (filename) ->
      if angular.isObject(filename) then buffer = filename
      else unless buffer = @getBufferByFilename(filename) then return notifier.warning """
        Cannot remove file: A file named '#{filename}' does not exist.
      """.trim()
  
      if (idx = $$history.indexOf(buffer.id)) < 0
        throw new Error("Session @buffers and $$history are out of sync")
  
      $$history.splice(idx, 1)
      delete @buffers[buffer.id]
      
      if idx == 0 and $$history.length then @activateBuffer(@buffers[$$history[0]])
      
      unless @$resetting then activity.client("session").record "files.remove",
        buffId: buffer.id
  
      @
  
  
    activateBuffer: (filename) ->
      debugger unless filename
      if angular.isObject(filename) then buffer = filename
      else unless buffer = @getBufferByFilename(filename) then return notifier.warning """
        Cannot activate file: A file named '#{filename}' does not exist.
      """.trim()
  
      if (idx = $$history.indexOf(buffer.id)) < 0
        throw new Error("Session @buffers and $$history are out of sync")
  
      $$history.splice(idx, 1)
      $$history.unshift(buffer.id)
      
      @activeBuffer = buffer
  
      @
  
  
    renameBuffer: (filename, new_filename) ->
      if angular.isObject(filename) then buffer = filename
      else unless buffer = @getBufferByFilename(filename) then return notifier.warning """
        Cannot rename file: A file named '#{filename}' does not exist.
      """.trim()
  
      buffer.filename = new_filename
      
      unless @$resetting then activity.client("session").record "files.rename",
        buffId: buffer.id
        filename: new_filename
        previous: filename
  
      @
]