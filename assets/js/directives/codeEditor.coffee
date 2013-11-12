require "../services/session.coffee"
require "../services/types.coffee"
require "../services/settings.coffee"
require "../services/annotations.coffee"
require "../services/splitter.coffee"


module = angular.module "plunker.directive.codeEditor", [
  "plunker.service.session"
  "plunker.service.types"
  "plunker.service.settings"
  "plunker.service.annotations"
  "plunker.service.splitter"
]

###
module.factory "editor", [ "types", (types) ->
  class ProjectFile
    constructor: (@filename, @content = "") ->

      @aceSession = new EditSession(@content or "")
      @aceSession.setUndoManager(new UndoManager())
      @aceSession.setUseWorker(true)
      @aceSession.setTabSize(settings.editor.tab_size)
      @aceSession.setUseWrapMode(!!settings.editor.wrap.enabled)
      @aceSession.setWrapLimitRange(settings.editor.wrap.range.min, settings.editor.wrap.range.max)
      
      @setMode()

      doc = aceSession.getDocument()
      
    setMode: (modeName) ->
      modeName ||= "ace/mode/" + types.getByFilename(filename).name
      
      @aceSession.setMode(modeName)
  
  class Project
    constructor: (@name) ->
      @files = []
      
    reset: (state = {files:[]}) ->
      file.destroy() for file in @files
      
      @files.push new ProjectFile(file.filename, file.content) for file in files
      
      @cursorMove(state.cursor.fileIndex, stateu.cursor.fileOffset) if state.cursor?
    
    cursorMove: (fileIndex, textOffset, textEndOffset) ->
      
    attachToSession: ->
      project = @
      client = session.createClient("project-#{@name}")
  
      client.on "reset", (e, snapshot) -> project.reset(snapshot)
      
      client.on "cursorSetFile", (e, snapshot) -> project.cursorMove(snapshot.cursor.fileIndex, snapshot.cursor.textOffset)
      
      client.on "cursorSetOffset", (e, snapshot) -> project.cursorMove(snapshot.cursor.fileIndex, snapshot.cursor.textOffset)
        
      client.on "fileCreate", (e, snapshot) -> project.files[e.index] = new ProjectFile(e.filename, e.content)
      
      client.on "fileRemove", (e, snapshot) ->
        [removed] = project.files.splice(e.index, 1)
        removed.destroy()
        file.
      
      client.on "fileRename", (e, snapshot) -> project.files[e.index].rename(e.filename)
      
      client.on "textInsert", (e, snapshot) -> 
        
      client.on "textRemove", (e, snapshot) ->

  projects = {}
  
  project: (projectName) -> project[projectName] ||= new Project(projectName)
]
###

module.directive "codeEditor", [ "$rootScope", "$timeout", "session", "types", "settings", "annotations", "splitter", ($rootScope, $timeout, session, types, settings, annotations, splitter) ->
  Split = ace.require("ace/split").Split
  AceEditor = ace.require("ace/editor").Editor
  Renderer = ace.require("ace/virtual_renderer").VirtualRenderer
  EditSession = ace.require("ace/edit_session").EditSession
  UndoManager = ace.require("ace/undomanager").UndoManager
  Range = ace.require("ace/range").Range
  
  config = ace.require("ace/config")
  
  restrict: "E"
  replace: true
  scope:
    active: "="
  template: """
    <div class="code-editor">
    </div>
  """
  link: ($scope, $el, attrs) ->
  
    split = window.split = new Split($el[0], "ace/theme/#{settings.editor.theme}", splitter.splits)
    editor = split.getCurrentEditor()
    
    client = session.createClient("code-editor")
    snippetManager = null
    buffers = []
    
    ace.config.loadModule "ace/ext/language_tools", ->
      editor.setOptions
        enableBasicAutocompletion: true
        enableSnippets: true
  
      snippetManager = ace.require("ace/snippets").snippetManager
    
    split.on "focus", (editor) ->
      editor.setBehavioursEnabled(true)
      editor.setOptions
        enableBasicAutocompletion: true
        enableSnippets: true

      splitter.active = split.$editors.indexOf(editor)
      
      unless $rootScope.$$phase then $scope.$apply ->
        client.cursorSetIndex(splitter.indices[splitter.active])
    
    $scope.$watch ( -> splitter.splits ), (splits, previous) ->
      split.setSplits(splits)
      
      return if splits is previous
      
      console.log "Splits", arguments...
      
      if splits > previous
        for idx in [previous...splits]
          console.log "setSession", [previous...splits], buffers[splitter.indices[idx]], idx
          #split.setSession buffers[splitter.indices[idx]], idx
      
      client.cursorSetIndex splitter.indices[splitter.active]
            
    $scope.$watch ( -> splitter.active ), (active, previous) ->
      return if active is previous
      
      ed.focus() if ed = split.getEditor(active) 
            
    $scope.$watch ( -> settings.editor.theme ), (theme) ->
      split.forEach (editor) ->
        editor.setTheme("ace/theme/#{theme}") if theme
    

    guessMode = (filename) -> "ace/mode/" + types.getByFilename(filename).name
    
    activateBuffer = (index) ->
      # Check if the buffer is already open in a split
      unless 0 > (found = splitter.indices.indexOf(index))
        # The buffer is already open at the split `found`, focus it
        debugger unless split.getEditor(found)
        split.getEditor(found).focus()

        # Force the splitter service to be in sync with the split object
        splitter.splits = split.getSplits()
        splitter.active = found

      # The buffer isn't already open, check splits
      else
        # activate is the EditSession we want to open
        activate = buffers[index]
  
        if splitter.splits > split.getSplits()
          split.setSplits(splitter.splits)
        
        # Update the splitter indices
        splitter.indices[splitter.active] = index
        
        split.setSession(activate, splitter.active)
        split.getEditor(splitter.active).focus()
    
    moveCursor = (offset) ->
      editor = split.getCurrentEditor()
      doc = editor.getSession().doc
      editor.moveCursorToPosition(doc.indexToPosition(offset))
    
    addAceSession = (index, file) ->
      watchers = []
    
      aceSession = new EditSession(file.content or "")
      aceSession.setUndoManager(new UndoManager())
      aceSession.setUseWorker(true)
      aceSession.setMode(guessMode(file.filename))
      aceSession.index$ = index
      
      watchers.push $scope.$watch ( -> settings.editor.tab_size ), (tabSize) ->
        aceSession.setTabSize(tabSize) if tabSize?

      watchers.push $scope.$watch ( -> settings.editor.wrap.enabled ), (wrap) ->
        aceSession.setUseWrapMode(wrap)

      watchers.push $scope.$watch ( -> settings.editor.wrap.range ), (range) ->
        aceSession.setWrapLimitRange(range.min, range.max) if range
      , true

      doc = aceSession.getDocument()
          
      handleChangeEvent = (e) ->
        # A change that is happening within a digest cycle is coming from an external source.
        # Do not handle these changes again.
        unless $rootScope.$$phase then $rootScope.$apply ->
          unless file = client.getFileByIndex(aceSession.index$)
            throw new Error("Buffers and session are out of sync")
        
          nl = doc.getNewLineCharacter()
          
          switch e.data.action
            when "insertText" then client.textInsert file.filename, doc.positionToIndex(e.data.range.start), e.data.text
            when "insertLines" then client.textInsert file.filename, doc.positionToIndex(e.data.range.start), e.data.lines.join(nl) + nl
            when "removeText" then client.textRemove file.filename, doc.positionToIndex(e.data.range.start), e.data.text
            when "removeLines" then client.textRemove file.filename, doc.positionToIndex(e.data.range.start), e.data.lines.join(nl) + nl
        
          if file.content != aceSession.getValue()
            console.error "[ERR] Local session out of sync", e.data, file.content, aceSession.getValue()
      
      handleChangeAnnotationEvent = (e) ->
        unless file = client.getFileByIndex(aceSession.index$)
          throw new Error("Buffers and session are out of sync")
        
        unless $rootScope.$$phase then $scope.$apply ->
          annotations.update(file.filename, aceSession.getAnnotations())
          
          $rootScope.$broadcast "updateAnnotatinos", file, aceSession.getAnnotations()

      buffers[index] = aceSession
      
      annotations.update file.filename, aceSession.getAnnotations()

      aceSession.on "change", handleChangeEvent
      aceSession.on "changeAnnotation", handleChangeAnnotationEvent

      aceSession.destroy = ->
        aceSession.off "change", handleChangeEvent
        aceSession.off "changeAnnotation", handleChangeAnnotationEvent
        
        unwatch() for unwatch in watchers

    removeAceSession = (index) ->
      unless remove = buffers[index] then debugger
      
      # If the session being removed is open in a split, reorganize things
      if split.getSplits() > 1
        unless 0 > found = splitter.indices.indexOf(index)
          idx = split.getSplits() - 1
          last = split.getEditor(idx).getSession()

          split.setSplits(split.getSplits() - 1)
          
          while idx > found
            idx--
            
            next = split.getEditor(idx).getSession()
            split.setSession(last, idx)
            last = next

          splitter.indices.splice found, 1
          splitter.splits--
      
      # Re-number existing buffers
      buffer.index$-- for buffer, idx in buffers when idx > index
      
      splitter.indices[idx] = old - 1 for old, idx in splitter.indices when idx > index
      
      buffers[index].destroy()
      buffers.splice index, 1
      
      if file = client.getFileByIndex(index)
        annotations.remove(file.filename)
      
    reset = (snapshot) ->
      removeAceSession(idx) for idx in [buffers.length - 1..0] by -1
      addAceSession(idx, file) for file, idx in snapshot.files
      
      splitter.active = 0
      splitter.splits = 1
      splitter.indices = []
      
      activateBuffer(snapshot.cursor.fileIndex)
    
    changeSessionMode = (index, filename) ->
      buffer.setMode(guessMode(filename)) if buffer = buffers[index]
        
    client.on "reset", (e, snapshot) -> reset(e.snapshot)
    
    client.on "cursorSetFile", (e, snapshot) ->
      activateBuffer(e.index)
    
    client.on "cursorSetOffset", (e, snapshot) ->
      moveCursor(e.offset)
      
    client.on "fileCreate", (e, snapshot) ->
      addAceSession(e.index, snapshot.files[e.index])
    
    client.on "fileRemove", (e, snapshot) ->
      removeAceSession(e.index)
      annotations.remove(e.filename)
    
    client.on "fileRename", (e, snapshot) ->
      changeSessionMode(e.index, e.filename)
      annotations.rename(e.filename, e.old_filename)
    
    client.on "textInsert", (e, snapshot) ->
      throw new Error("Received textInsert event for a file not being tracked") unless aceSession = buffers[e.index]
      aceSession.doc.insert aceSession.doc.indexToPosition(e.offset), e.text
      
    client.on "textRemove", (e, snapshot) ->
      throw new Error("Received textInsert event for a file not being tracked") unless aceSession = buffers[e.index]
      aceSession.doc.remove Range.fromPoints(aceSession.doc.indexToPosition(e.offset), aceSession.doc.indexToPosition(e.offset + e.text.length))
    
    reset(client.getSnapshot())
    activateBuffer(client.getCursorFileIndex())
    moveCursor(client.getCursorTextOffset())
    
    # Resize the ace component whenever we get a reflow event from border-layout
    $scope.$on "border-layout-reflow", -> $timeout -> split.resize()

    $timeout ->
      split.resize()
    , 100
    
    $scope.$on "$destroy", ->
      session.destroyClient("code-editor")

]