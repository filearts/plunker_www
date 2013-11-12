require "../services/session.coffee"
require "../services/types.coffee"
require "../services/settings.coffee"
require "../services/splitter.coffee"


module = angular.module "plunker.directive.aceEditor", [
  "plunker.service.session"
  "plunker.service.settings"
  "plunker.service.types"
  "plunker.service.splitter"
]

module.service "aceSessions", ["$rootScope", "session", "settings", "types", ($rootScope, session, settings, types) ->
  EditSession = ace.require("ace/edit_session").EditSession
  UndoManager = ace.require("ace/undomanager").UndoManager
  Range = ace.require("ace/range").Range
  
  class File
    constructor: (@filename, content) ->
      @$destructors = [] # Array of functions to call on destroy
      
      @undoManager = new UndoManager
      @editSession = new EditSession(content)
      @editSession.setUndoManager(@undoManager)
      @editSession.setUseWorker(true)
      
      @document = @editSession.getDocument()
      
      @$destructors.push $rootScope.$watch ( => @filename ), (filename) =>
        @editSession.setMode "ace/mode/" + types.getByFilename(filename).name
      
      @$destructors.push $rootScope.$watch ( -> settings.editor.tab_size ), (tabSize) =>
        @editSession.setTabSize(tabSize) if tabSize?
          
      @$destructors.push $rootScope.$watch ( -> settings.editor.wrap.enabled ), (wrap) =>
        @editSession.setUseWrapMode(wrap)

      @$destructors.push $rootScope.$watch ( -> settings.editor.wrap.range ), (range) =>
        @editSession.setWrapLimitRange(range.min, range.max) if range
      , true
      
      @$setupEventHandlers()
    
    $setupEventHandlers: ->
      handleChangeEvent = (e) =>
        # A change that is happening within a digest cycle is coming from an external source.
        # Do not handle these changes again.
        unless $rootScope.$$phase then $rootScope.$apply =>
          unless file = client.getFileByIndex(@getIndex())
            throw new Error("Buffers and session are out of sync")
        
          nl = @document.getNewLineCharacter()
          
          switch e.data.action
            when "insertText" then client.textInsert @filename, @document.positionToIndex(e.data.range.start), e.data.text
            when "insertLines" then client.textInsert @filename, @document.positionToIndex(e.data.range.start), e.data.lines.join(nl) + nl
            when "removeText" then client.textRemove @filename, @document.positionToIndex(e.data.range.start), e.data.text
            when "removeLines" then client.textRemove @filename, @document.positionToIndex(e.data.range.start), e.data.lines.join(nl) + nl
        
          if file.content != @document.getValue()
            console.error "[ERR] Local session out of sync", @filename, file.content, @document.getValue()

      @editSession.on "change", handleChangeEvent
      
      @$destructors.push =>
        @editSession.off "change", handleChangeEvent
    
    getIndex: -> aceSessions.indexOf(this)
    
    rename: (@filename) ->
    
    textInsert: (offset, text) -> @document.insert @document.indexToPosition(offset), text
    textRemove: (offset, text) -> @document.remove Range.fromPoints(@document.indexToPosition(offset), @document.indexToPosition(offset + text.length))
    
    destroy: ->
      destructor() for destructor in @$destructors
  
    # End of File class
  

    
  client = session.createClient("project")
  aceSessions = []
   
  # Callbacks that handle operations coming *from* the session stream
  doFileCreate = (index, filename, content = "") ->
    aceSessions.splice index, 0, new File(filename, content)
  
  doFileRemove = (index) ->
    aceSessions[index].destroy()
    aceSessions.splice index, 1
  
  doFileRename = (index, filename) ->
    aceSessions[index].rename(filename)
  
  doTextInsert = (index, offset, text) ->
    aceSessions[index].textInsert(offset, text)
  
  doTextRemove = (index, offset, text) ->
    aceSessions[index].textRemove(offset, text)
  
  doReset = (files) ->
    doFileRemove(aceSessions.length - 1) while aceSessions.length
    doFileCreate(idx, file.filename, file.content) for file, idx in files
  
  # Register the above event handlers with the session client
  client.on "reset", (e, snapshot) -> doReset(snapshot.files)
  
  client.on "fileCreate", (e, snapshot) -> doFileCreate(e.index, e.filename, e.text)
  client.on "fileRemove", (e, snapshot) -> doFileRemove(e.index)
  client.on "fileRename", (e, snapshot) -> doFileRename(e.index, e.filename)  
  client.on "textInsert", (e, snapshot) -> doTextInsert(e.index, e.offset, e.text)
  client.on "textRemove", (e, snapshot) -> doTextRemove(e.index, e.offset, e.text)
  
  doReset(client.getSnapshot().files)
  
  # Public API:
  findByIndex: (idx) -> aceSessions[idx]
  findByFilename: (filename) -> aceSessions[client.getFileIndex(filename)]
]


module.directive "aceEditor", ["$rootScope", "settings", "aceSessions", ($rootScope, settings, aceSessions) ->                               
  Editor = ace.require("ace/editor").Editor
  Renderer = ace.require("ace/virtual_renderer").VirtualRenderer
  
  # Directive definition:
  require: "^?aceSplitEditor"
  restrict: "A"
  link: ($scope, $element, $attrs, parent) ->
    editor = new Editor(new Renderer($element[0], "ace/theme/#{settings.editor.theme || 'textmate'}"))
    editor.setBehavioursEnabled(true)

    ace.config.loadModule "ace/ext/language_tools", ->
      editor.setOptions
        enableBasicAutocompletion: true
        enableSnippets: true
    
    $scope.$watch ( -> settings.editor.theme ), (theme) -> editor.setTheme "ace/theme/#{settings.editor.theme || 'textmate'}"
    
    console.log "$attrs", $attrs, $scope.session
                               
    $scope.$watch $attrs.aceEditor, (fileIndex) ->
      return unless angular.isNumber(fileIndex)
      throw new Error("Invalid file index") unless file = aceSessions.findByIndex(fileIndex)
      
      editor.setSession(file.editSession)
      editor.focus()
    
    # Clean up the editor 
    $scope.$on "$destroy", -> editor.destroy()
    $scope.$on "border-layout-reflow", -> editor.resize()    
  ]

module.directive "aceSplitEditor", ["$rootScope", "iface", ($rootScope, iface) ->
  # Directive definition:
  template: """
    <border-layout>
      <pane options="{anchor: anchor, size: size, handle: 4}" ng-repeat="split in splits">
        <div ace-editor="{{split.fileIndex}}"></div>
      </pane>
    </border-layout>
  """
  
  link: ($scope, $element, $attrs) ->
    $scope.splits = []
    
    $scope.$watch "splits.length", (length) ->
      $scope.size = "#{100 / length}% - 4px"
    $scope.$watchCollection ( -> iface.getSplitIndices() ), (indices, prevIndices) ->
      
]

module.controller "CodeEditorController", ["$scope", "session", "splitter", ($scope, session, splitter) ->
  $scope.session = client = session.createClient("CodeEditorController")
  $scope.panes = [
    config:
      anchor: "east"
      size: "50% - 2px"
      handle: 4
    index: 0
  ,
    config:
      anchor: "center"
    index: 1

  ]
                    
  $scope.$watchCollection ( -> splitter.indices), (indices) ->
    return
    console.log "$watchCollection", arguments...
    return unless indices
    $scope.panes.length = 0
    size = indices.length
    paneSize = 1 / size
    for idx in indices
      if idx == size - 1 then $scope.panes.push
        index: idx
        pane:
          anchor: "center"
      else $scope.panes.push
        index: idx
        pane:
          anchor: "east"
          size: "#{paneSize * 100}% - 2px"
          handleSize: 4
]