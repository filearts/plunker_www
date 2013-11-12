require "../../vendor/share/share.uncompressed.js"


module = angular.module "plunker.service.session", [
]

module.service "session", class Session
  # SessionClient is the interface through-which subscribers can issue operations on the session
  class SessionClient
    constructor: (@name, @session) ->
      @listeners = {}
      
    on: (eventName, listener) -> (@listeners[eventName] ||= []).push(listener)
    off: (eventName, listener) -> @listeners[eventName].splice(idx, 1) unless !@listeners[eventName] or 0 > (idx = @listeners[eventName].indexOf(listener))
    
    _applyOp: (op) -> @_applyOps [op]
    _applyOps: (ops) -> @session.applyOps @name, ops
    
    _handleOp: (sourceClientName, op, snapshot) ->
      if op.p.length is 0
        @_emit "reset",
          snapshot: op.oi
          old_snapshot: op.od
      else
        switch op.p[0]
          when "cursor"
            if op.p[1] is "fileIndex" then @_emit "cursorSetFile",
              filename: snapshot.files[op.oi].filename
              prev_filename: snapshot.files[op.od].filename
              index: op.oi
              prev_index: op.od
            else if op.p[1] is "textOffset" then @_emit "cursorSetOffset",
              offset: op.oi
              prev_offset: op.od
          when "description"
            # Assume si/sd ops at offset = 0
            return unless op.p[1] is 0
            return unless op.si and op.sd
            
            @_emit "setDescription",
              description: op.si
              old_description: op.sd
          when "tags"
            return unless op.li or op.ld
            return if op.p.length != 2
            
            if op.li then @_emit "tagAdd",
              tagName: op.li
              index: op.p[1]
            else if op.ld then @_emit "tagRemove",
              tagName: op.ld
              index: op.p[2]
          when "files"
            # This is a file creation/removal
            if op.p.length is 2
              if op.li then @_emit "fileCreate",
                filename: op.li.filename
                index: op.p[1]
                content: op.li.content
              else if op.ld then @_emit "fileRemove",
                filename: op.ld.filename
                index: op.p[1]
                content: op.ld.content
            
            else if op.p[2] is "filename"
              @_emit "fileRename",
                filename: op.oi
                index: op.p[1]
                old_filename: op.od
                
            else if op.p[2] is "content"
              filename = snapshot.files[op.p[1]].filename
              
              if op.si then @_emit "textInsert",
                filename: filename
                index: op.p[1]
                text: op.si
                offset: op.p[3]
              if op.sd then @_emit "textRemove",
                filename: filename
                index: op.p[1]
                text: op.sd
                offset: op.p[3]
                
      @_emit "remoteOp", {op, snapshot}

    _emit: (eventName, e) ->
      snapshot = @getSnapshot()
      e.eventName = eventName
      
      listener(e, snapshot) for listener in @listeners[eventName] if @listeners[eventName]
    
    getCursorFileIndex: -> @session.snapshot.cursor.fileIndex
    
    getCursorTextOffset: -> @session.snapshot.cursor.textOffset
    
    getDescription: -> @session.snapshot.description
    
    # Return value is just like indexOf (>= 0 means found, -1 means not found)
    getFileIndex: (filename) ->
      return idx for file, idx in @session.snapshot.files when file.filename is filename
      return -1
    
    getFileByIndex: (idx) ->
      if angular.isString(idx) then idx = @getFileIndex(idx)
      
      @session.snapshot.files[idx]
    
    getFile: (filename) ->
      return file for file in @session.snapshot.files when file.filename is filename
    
    getNumFiles: -> return @session.snapshot.files?.length or 0
    
    getNumTags: -> return @session.snapshot.tags?.length or 0
    
    getSnapshot: -> return @session.snapshot
    
    # Return value is just like indexOf (>= 0 means found, -1 means not found)
    getTagIndex: (tagName) ->
      return idx for tag, idx in @session.snapshot.tags when tag is tagName
      return -1
    
    hasFile: (filename) -> return @getFileIndex(filename) >= 0

    hasFileIndex: (idx) -> return @getFileByIndex(idx)?
    
    hasTag: (tagName) -> return @getTagIndex(tagName) >= 0
    
    isValidTag: (tagName) -> return /^[-_a-z0-9\.\[\]]+$/i.test(tagName)
    
    isValidFile: (file) -> return @isValidFilename(file.filename) && angular.isString(file.content)
    
    isValidFilename: (filename) -> return /^[-_a-z0-9\.][-_a-z0-9\.\/]+$/i.test(filename)
    
    
    
    reset: (json = {}) ->
      json.description ||= ""
      json.tags ||= []
      json.cursor ||= { fileIndex: 0, textOffset: 0 }
      
      throw new Error("Reset failed. Description must be a string.") unless angular.isString(json.description)
      throw new Error("Reset failed. Tags must be an array.") unless angular.isArray(json.tags)
      throw new Error("Reset failed. Invalid tag: #{tagName}.") for tagName in json.tags when !@isValidTag(tagName)
      throw new Error("Reset failed. Files must be an array.") unless angular.isArray(json.files)
      throw new Error("Reset failed. Invalid file: #{JSON.stringify(file)}.") for file in json.files when !@isValidFile(file)
      throw new Error("Reset failed. There must be at least one file.") unless json.files.length
    
      @_applyOp
        p: []
        od: angular.copy(@getSnapshot())
        oi: json
    
    cursorSetFile: (filename) ->
      throw new Error("Unable set the active file. File does not exist: #{filename}") unless @hasFile(filename)
      
      idx = @getFileIndex(filename)
      
      @_applyOp
        p: ["cursor", "fileIndex"]
        od: @getCursorFileIndex()
        oi: idx
    
    cursorSetIndex: (idx) ->
      throw new Error("Unable set the active file. File does not exist: #{idx}") unless @hasFileIndex(idx)
      
      @_applyOp
        p: ["cursor", "fileIndex"]
        od: @getCursorFileIndex()
        oi: idx
    
    cursorSetOffset: (offset) ->
      @_applyOp
        p: ["cursor", "textOffset"]
        od: @getCursorTextOffset()
        oi: offset
    
    setDescription: (description = "") ->
      @_applyOp
        p: ["description", 0]
        sd: @getDescription()
        si: description
    
    
    
    fileCreate: (filename, content = "") ->
      throw new Error("Unable to create file. Invalid filename: #{filename}") unless @isValidFilename(filename)
      throw new Error("Unable to create file. File already exists: #{filename}") if @hasFile(filename)
      
      idx = @getNumFiles()
      
      @_applyOp
        p: ["files", idx]
        li: {filename, content}
    
    fileRename: (filename, new_filename) ->
      throw new Error("Unable to create file. Invalid filename: #{new_filename}") unless @isValidFilename(new_filename)
      throw new Error("Unable to rename file. File does not exist: #{filename}") unless @hasFile(filename)
      throw new Error("Unable to rename file. A file already exists named: #{new_filename}") if @hasFile(new_filename)

      idx = @getFileIndex(filename)
      
      @_applyOp
        p: ["files", idx, "filename"]
        od: filename
        oi: new_filename

    fileRemove: (filename) ->
      throw new Error("Unable to remove file. File does not exist: #{filename}") unless @hasFile(filename)
      throw new Error("Unable to remove file. You can not remove all files.") if @getNumFiles() <= 1

      idx = @getFileIndex(filename)
      
      @cursorSetIndex(0)
    
      @_applyOp
        p: ["files", idx]
        ld: @getFile(filename)
        
    
    
    textInsert: (filename, offset, text) ->
      throw new Error("Unable to insert text. File does not exist: #{filename}") unless @hasFile(filename)
      
      idx = @getFileIndex(filename)

      @_applyOp
        p: ["files", idx, "content", offset]
        si: text

    textRemove: (filename, offset, text) ->
      throw new Error("Unable to remove text. File does not exist: #{filename}") unless @hasFile(filename)
      
      idx = @getFileIndex(filename)

      @_applyOp
        p: ["files", idx, "content", offset]
        sd: text
    
    
    
    tagAdd: (tagName) ->
      throw new Error("Unable to add tag. Invalid tag: #{tagName}") unless @isValidTag(tagName)
      throw new Error("Unable to add tag. Tag already exists: #{tagName}") if @hasTag(tagName)
      
      idx = @getNumTags()
      
      @_applyOp
        p: ["tags", idx]
        li: tagName

    tagRemove: (tagName) ->
      throw new Error("Unable to remove tag. Tag not found: #{tagName}") unless @hasTag(tagName)
      
      idx = @getTagIndex(tagName)
      
      @_applyOp
        p: ["tags", idx]
        ld: tagName
  
  
  constructor: ->
    @$clients = {}
    
    @snapshot = {}
    @iface = @createClient("session")
    
    @iface.reset
      files: [
        filename: "index.html"
        content: ""
      ]
  
  createClient: (clientName) ->
    #throw new Error("Unable to create client. Client already created: #{clientName}.") if @$clients[clientName]
    
    session = @
    
    @$clients[clientName] ||= new SessionClient(clientName, session)
  
  destroyClient: (clientName) ->
    delete @$clients[clientName] if @$clients[clientName]
  
  applyOps: (sourceClientName, ops) ->
    postSnapshot = ottypes.json0.apply @snapshot, ops
    
    #console.log "[OT] op", op for op in ops
    #console.log "[OT] snapshot", angular.copy(@snapshot)
    
    angular.copy postSnapshot, @snapshot unless @snapshot == postSnapshot
    
    for clientName, client of @$clients when clientName != sourceClientName
      client._handleOp(sourceClientName, op, @snapshot) for op in ops
      
