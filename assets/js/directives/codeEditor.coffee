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

      
      doc = aceSession.getDocument()
          
      handleChangeEvent = (e) ->
        unless $rootScope.$$phase then $scope.$apply ->
          nl = doc.getNewLineCharacter()
          
          switch e.data.action
            when "insertText" then client.textInsert file.filename, doc.positionToIndex(e.data.range.start), e.data.text
            when "insertLines" then client.textInsert file.filename, doc.positionToIndex(e.data.range.start), e.data.lines.join(nl) + nl
            when "removeText" then client.textRemove file.filename, doc.positionToIndex(e.data.range.start), e.data.text
            when "removeLines" then client.textRemove file.filename, doc.positionToIndex(e.data.range.start), e.data.lines.join(nl) + nl
      
      handleChangeAnnotationEvent = (e) ->
        unless $rootScope.$$phase then $scope.$apply ->
          if (idx = client.getFileIndex(file.filename)) < 0
            throw new Error("Buffers and session are out of sync for: #{file.filename}")
          
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