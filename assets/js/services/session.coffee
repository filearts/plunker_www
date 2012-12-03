#= require "../services/plunks"
#= require "../services/notifier"

module = angular.module "plunker.session", [
  "plunker.plunks"
  "plunker.notifier"
]

module.service "session", [ "$q", "plunks", "notifier", ($q, plunks, notifier) ->
  new class Session
    $$savedBuffers = {}
    $$history = []
  
    $$counter = 0
  
    $$uid = (prefix = "__") ->  prefix + ($$counter++)
  
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
  
      @buffers = {}
  
      @reset()
    
  
    getActiveBuffer: ->
      throw new Error("Attempting return the active buffer while the Session is out of sync") unless $$history.length
  
      buffId = $$history[0]
      buffer = @buffers[buffId]
  
    getBufferByFilename: (filename) ->
      for bufId, buffer of @buffers
        if buffer.filename == filename
          return buffer
  
      return
      
    getEditPath: -> @plunk?.id or @source or ""
  
    toJSON: ->
      json =
        description: @description
        tags: @tags
        files: {}
  
      for buffId, buffer of @buffers
        json.files[buffer.filename] =
          filename: buffer.filename
          content: buffer.content
  
      json
  
    reset: (options = {}) ->
      $$savedBuffers = {}
      $$history = []
  
      @plunk = null
      @plunk = plunks.findOrCreate(options.plunk) if options.plunk
  
      @source = options.source or ""
  
      @description = options.description or ""
      @tags = options.tags or []
  
      angular.copy {}, @buffers
  
      $$history.length = 0
      
      @addBuffer(file.filename, file.content) for filename, file of options.files if options.files
  
      @addBuffer("index.html", "") unless $$history.length
  
      @activateBuffer("index.html") if @getBufferByFilename("index.html")

      @updated_at = Date.now()

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
  
    save: ->
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
            fileDelta = fileDeltas[prev_file.filename]
    
            if buffer.filename != prev_file.filename
               fileDelta.filename = buffer.filename
            if buffer.content != prev_file.content
               fileDelta.content = buffer.content
           else
             fileDeltas[buffer.filename] =
               filename: buffer.filename
               content: buffer.content
         
        for fn, chg of fileDeltas
          delta.files = fileDeltas
          break

        $$asyncOp.call @, "save", (dfd) ->
          plunk.save(delta).then (plunk) ->
            $$savedBuffers = inFlightBuffers
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

        $$asyncOp.call @, "save", (dfd) ->
          plunk.save(delta).then (plunk) ->
            self.plunk = plunk
            $$savedBuffers = inFlightBuffers
            notifier.success "Plunk created"
            dfd.resolve(self)
          , (err) ->
            dfd.reject(err)
            notifier.error """
              Save failed: #{err}
            """.trim()

  
    fork: ->
      unless @plunk?.isSaved() then return notifier.warning """
        Fork cancelled: You cannot fork a plunk that does not exist.
      """.trim()
  
      json = @toJSON()
      self = @
      
      lastSavedBuffers = angular.copy($$savedBuffers)
      inFlightBuffers = do ->
        buffers = {}
        
        for id, buffer of self.buffers
          buffers[id] =
            filename: buffer.filename
            content: buffer.content
      
      $$asyncOp.call @, "fork", (dfd) ->
        plunks.fork(self.plunk, json).then (plunk) ->
          self.plunk = plunk
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
  
      buffId = $$uid()
      
      @buffers[buffId] =
        id: buffId
        filename: filename
        content: content
  
      $$history.push(buffId)
  
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
      
      @updated_at = Date.now()
  
      @
]