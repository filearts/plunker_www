require "../services/session.coffee"
require "../services/types.coffee"
require "../services/settings.coffee"
require "../services/annotations.coffee"

module = angular.module "plunker.directive.codeEditor", [
  "plunker.service.session"
  "plunker.service.types"
  "plunker.service.settings"
  "plunker.service.annotations"
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

module.directive "codeEditor", [ "$rootScope", "$timeout", "session", "types", "settings", "annotations", ($rootScope, $timeout, session, types, settings, annotations) ->
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
    editor = new AceEditor(new Renderer($el[0], "ace/theme/#{settings.editor.theme}"))
    client = session.createClient("code-editor")
    snippetManager = null
    buffers = []
    
    ace.config.loadModule "ace/ext/language_tools", ->
      editor.setOptions
        enableBasicAutocompletion: true
        enableSnippets: true
  
      snippetManager = ace.require("ace/snippets").snippetManager
      
    $scope.$watch ( -> settings.editor.theme ), (theme) ->
      editor.setTheme("ace/theme/#{theme}") if theme
    

    guessMode = (filename) -> "ace/mode/" + types.getByFilename(filename).name
    
    activateBuffer = (index) ->
      editor.setSession(buffers[index])
      editor.focus()
    
    moveCursor = (offset) ->
      doc = editor.session.doc
      editor.moveCursorToPosition(doc.indexToPosition(offset))
    
    addAceSession = (index, file) ->
      aceSession = new EditSession(file.content or "")
      aceSession.setUndoManager(new UndoManager())
      aceSession.setUseWorker(true)
      aceSession.setTabSize(settings.editor.tab_size)
      aceSession.setUseWrapMode(!!settings.editor.wrap.enabled)
      aceSession.setWrapLimitRange(settings.editor.wrap.range.min, settings.editor.wrap.range.max)
      aceSession.setMode(guessMode(file.filename))
      aceSession.index$ = index

      
      doc = aceSession.getDocument()
          
      handleChangeEvent = (e) ->
        unless file = client.getFileByIndex(aceSession.index$)
          throw new Error("Buffers and session are out of sync")
        
        unless $rootScope.$$phase then $scope.$apply ->
          nl = doc.getNewLineCharacter()
          
          switch e.data.action
            when "insertText" then client.textInsert file.filename, doc.positionToIndex(e.data.range.start), e.data.text
            when "insertLines" then client.textInsert file.filename, doc.positionToIndex(e.data.range.start), e.data.lines.join(nl) + nl
            when "removeText" then client.textRemove file.filename, doc.positionToIndex(e.data.range.start), e.data.text
            when "removeLines" then client.textRemove file.filename, doc.positionToIndex(e.data.range.start), e.data.lines.join(nl) + nl
      
        if file.content != aceSession.getValue()
          console.error "[ERR] Local session out of sync", e
      
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

    removeAceSession = (index) ->
      unless buffers[index] then debugger
      
      # Re-number existing buffers
      buffer.index$-- for buffer, idx in buffers when idx > index
      
      buffers[index].destroy()
      buffers.splice index, 1
      
      if file = client.getFileByIndex(index)
        annotations.remove(file.filename)
      
    reset = (snapshot) ->
      removeAceSession(idx) for idx in [buffers.length - 1..0] by -1
      addAceSession(idx, file) for file, idx in snapshot.files
      
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
    $scope.$on "border-layout-reflow", -> editor.resize()

    $timeout ->
      editor.resize()
    , 100

]