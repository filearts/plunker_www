#= require ../services/plunks
#= require ../services/notifier
#= require ../services/activity

module = angular.module "plunker.session", [
  "plunker.plunks"
  "plunker.notifier"
  "plunker.activity"
]

module.service "session", [ "$q", "$timeout", "plunks", "notifier", "activity", ($q, $timeout, plunks, notifier, activity) ->

  genid = (len = 16, prefix = "", keyspace = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789") ->
    prefix += keyspace.charAt(Math.floor(Math.random() * keyspace.length)) while len-- > 0
    prefix

  new class Session
    $$savedBuffers = {}
    $$history = []
  
    $$counter = 0
  
    $$uid = (prefix = "__") ->  prefix + genid()
  
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
  
      @reset()
      
      window.onbeforeunload = =>
        if @isDirty() then "You have unsaved work on this Plunk."
    
    isSaved: -> !!@plunk and @plunk.isSaved()
    isWritable: -> !!@plunk and @plunk.isWritable()
    
    isDirty: ->
      if @plunk and (@description != @plunk.description or !angular.equals(@tags, @plunk.tags)) then true
      else if @updated_at <= @reset_at then false
      else if @saved_at is null then true
      else if @saved_at < @updated_at then true
      else false
  
    getActiveBuffer: ->
      throw new Error("Attempting return the active buffer while the Session is out of sync") unless $$history.length
  
      buffId = $$history[0]
      buffer = @buffers[buffId]
  
    getBufferByFilename: (filename) ->
      for bufId, buffer of @buffers
        if buffer.filename == filename
          return buffer
  
      return
      
    getEditPath: ->
      if @plunk then @plunk.id or ""
      else @source or ""
  
    toJSON: (options = {}) ->
      json =
        description: @description
        tags: @tags
        'private': @private
        files: {}
  
      for buffId, buffer of @buffers
        json.files[buffer.filename] =
          filename: buffer.filename
          content: buffer.content
        json.files[buffer.filename].id = buffId if options.includeBufferId
  
      json
  
    reset: (json = {}, options = {}) ->
      $$savedBuffers = {}
      $$history = []
  
      @resetting = true
      
      unless options.soft
        @plunk = null
        @plunk = plunks.findOrCreate(json.plunk) if json.plunk
  
        @source = json.source or ""
  
      @description = json.description or ""
      @tags = json.tags or []
      @private = !!json.private
  
      angular.copy {}, @buffers
  
      $$history.length = 0
      
      @addBuffer(file.filename, file.content, file) for filename, file of json.files if json.files
  
      @addBuffer("index.html", "") unless $$history.length
  
      @activateBuffer("index.html") if @getBufferByFilename("index.html")

      @updated_at = Date.now()
      @reset_at = Date.now() + 36000 # Far in future to make sure isDirty is false until next tick
      @saved_at = null
      
      activity.record "reset", [], @toJSON(includeBufferId: true)

      
      # Update @reset_at to next tick value to capture subsequent change events in setting initial value
      $timeout =>
        @reset_at = Date.now()
        @resetting = false

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

      lastSavedBuffers = angular.copy($$savedBuffers)
      inFlightBuffers = do ->
        buffers = {}
        
        for id, buffer of self.buffers
          buffers[id] =
            filename: buffer.filename
            content: buffer.content
        
        buffers
      inFlightSavedAt = Date.now()
        

      if plunk = @plunk
        delta = {}
        delta.description = @description if @description != plunk.description
      
        # Update tags
        if plunk.isSaved()
          tagDelta = {}
          tagsChanged = false
    
          for tag in @tags
            tagDelta[tag] = true
            tagsChanged = true
    
          for tag in plunk.tags when tag not in @tags
            tagDelta[tag] = false
            tagsChanged = true
    
          if tagsChanged
            delta.tags = tagDelta
        else
          delta.tags = angular.copy(@tags)
    
        fileDeltas = {}
    
        # Schedule all files for deletion, initially
        for id, prev_file of $$savedBuffers
          fileDeltas[prev_file.filename] = null
    
        for id, buffer of @buffers
          if prev_file = $$savedBuffers[id]
            fileDelta = {}
    
            if buffer.filename != prev_file.filename
              fileDelta.filename = buffer.filename
            if buffer.content != prev_file.content
              fileDelta.content = buffer.content
            
            if fileDelta.filename or fileDelta.content
              fileDeltas[prev_file.filename] = fileDelta
            else
              delete fileDeltas[prev_file.filename]
          else
            fileDeltas[buffer.filename] =
              filename: buffer.filename
              content: buffer.content
         
        for fn, chg of fileDeltas
          delta.files = fileDeltas
          break
          
        delta = angular.extend delta, options

        $$asyncOp.call @, "save", (dfd) ->
          plunk.save(delta).then (plunk) ->
            $$savedBuffers = inFlightBuffers
            self.saved_at = inFlightSavedAt
            notifier.success "Plunk updated"
            dfd.resolve(self)
          , (err) ->
            $$savedBuffers = lastSavedBuffers
    
            dfd.reject(err)
            notifier.error """
              Save failed: #{err}
            """.trim()

      else
        delta = @toJSON()
        plunk = plunks.findOrCreate()

        delta = angular.extend delta, options

        $$asyncOp.call @, "save", (dfd) ->
          plunk.save(delta).then (plunk) ->
            self.saved_at = inFlightSavedAt
            $$savedBuffers = inFlightBuffers
            self.plunk = plunk
            notifier.success "Plunk created"
            dfd.resolve(self)
          , (err) ->
            dfd.reject(err)
            notifier.error """
              Save failed: #{err}
            """.trim()

  
    fork: (options = {}) ->
      unless @plunk?.isSaved() then return notifier.warning """
        Fork cancelled: You cannot fork a plunk that does not exist.
      """.trim()
  
      json = angular.extend @toJSON(), options
      self = @
      
      lastSavedBuffers = angular.copy($$savedBuffers)
      inFlightBuffers = do ->
        buffers = {}
        
        for id, buffer of self.buffers
          buffers[id] =
            filename: buffer.filename
            content: buffer.content
      inFlightSavedAt = Date.now()
      
      $$asyncOp.call @, "fork", (dfd) ->
        plunks.fork(self.plunk, json).then (plunk) ->
          self.plunk = plunk
          self.saved_at = inFlightSavedAt
          $$savedBuffers = inFlightBuffers
  
          dfd.resolve(self)
        , (err) ->
          $$savedBuffers = lastSavedBuffers
  
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
  
      $$history.push(buffId)
      
      activity.record "files.add", ["files", buffId], angular.copy(@buffers[buffId]) unless @resetting
  
      @activateBuffer(filename) if options.activate is true
  
      @
  
    removeBuffer: (filename) ->
      unless buffer = @getBufferByFilename(filename) then return notifier.warning """
        Cannot remove file: A file named '#{filename}' does not exist.
      """.trim()
  
      if (idx = $$history.indexOf(buffer.id)) < 0
        throw new Error("Session @buffers and $$history are out of sync")
  
      $$history.splice(idx, 1)
      delete @buffers[buffer.id]
      
      activity.record "files.remove", ["files", buffer.id], angular.copy(buffer) unless @resetting
  
      @
  
  
    activateBuffer: (filename) ->
      unless buffer = @getBufferByFilename(filename) then return notifier.warning """
        Cannot activate file: A file named '#{filename}' does not exist.
      """.trim()
  
      if (idx = $$history.indexOf(buffer.id)) < 0
        throw new Error("Session @buffers and $$history are out of sync")
  
      $$history.splice(idx, 1)
      $$history.unshift(buffer.id)
  
      @
  
  
    renameBuffer: (filename, new_filename) ->
      unless buffer = @getBufferByFilename(filename) then return notifier.warning """
        Cannot rename file: A file named '#{filename}' does not exist.
      """.trim()
  
      buffer.filename = new_filename
      
      activity.record "files.rename", ["files", buffer.id, "filename"], filename, new_filename unless @resetting
      
      @updated_at = Date.now()
  
      @
]