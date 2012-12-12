#= require ../../vendor/ace/src/ace

#= require ../services/session
#= require ../services/modes
#= require ../services/settings
#= require ../services/annotations
#= require ../services/cursor

module = angular.module "plunker.ace", [
  "plunker.session"
  "plunker.modes"
  "plunker.settings"
  "plunker.annotations"
  "plunker.cursor"
]


module.directive "plunkerEditSession", [ "$timeout", "modes", "session", "settings", "annotations", ($timeout, modes, editsession, settings, annotations) ->
  EditSession = require("ace/edit_session").EditSession
  UndoManager = require("ace/undomanager").UndoManager
  
  
  restrict: "E"
  replace: true
  require: ["?ngModel", "^plunkerAce"]
  scope:
    buffer: "="
  template: """
    <div class="plunker-edit-session"">
    </div>
  """
  link: ($scope, $el, attrs, [model, aceEditor]) ->
    buffer = $scope.buffer
    initial = true
    
    session = new EditSession(model.$modelValue)
    session.setUndoManager(new UndoManager())
    session.setTabSize(settings.editor.tab_size)
    session.setUseWorker(true)
    
    $timeout -> initial = false
    
    updateModel = (fn) ->
      unless initial then $scope.$apply(fn)
      else fn()
    
    model.$render = -> 
      session.setValue(model.$modelValue)
    
    session.on "change", (delta) ->
      updateModel -> model.$setViewValue(session.getValue())
      
    session.on "changeAnnotation", ->
      updateModel -> angular.copy session.getAnnotations(), annotations[buffer.id]

    $scope.$watch "buffer.filename", (filename) ->
      mode = modes.findByFilename(filename)
      session.setMode("ace/mode/#{mode.name}")
      editsession.updated_at = Date.now()
    
    $scope.$watch "buffer.content", (content) ->
      editsession.updated_at = Date.now()
    
    $scope.$watch ( -> settings.editor.tab_size ), (tab_size) ->
      session.setTabSize(tab_size)
    
    $scope.$watch ( -> settings.editor.soft_tabs ), (soft_tabs) ->
      session.setUseSoftTabs(!!soft_tabs)
      
    aceEditor.sessions[buffer.id] = session

    annotations[buffer.id] = []
    
    $scope.$on "$destroy", ->
      delete aceEditor.sessions[buffer.id]
      delete annotations[buffer.id]
]

module.directive "plunkerAce", [ "$timeout", "session", "settings", "cursor", ($timeout, session, settings, cursor) ->
  Editor = require("ace/editor").Editor
  Renderer = require("ace/virtual_renderer").VirtualRenderer
  

  restrict: "E"
  require: ["plunkerAce", "ngModel"]
  replace: true
  template: """
    <div class="plunker-ace" ng-model="cursor">
      <plunker-edit-session ng-model="buffer.content" buffer="buffer" ng-repeat="(id, buffer) in session.buffers">
      </plunker-edit-session>
      <div class="plunker-ace-canvas"></div>
    </div>
  """
  controller: class AceController
    constructor: ->
      @sessions = {}
      @editor = null

    edit: (@el) ->
      @editor = new Editor(new Renderer(@el, "ace/theme/textmate"))
        
  link: ($scope, $el, attrs, [ctrl, model]) ->
    $scope.cursor = cursor
    ignoreCursorMove = false
    
    # Configure ACE to allow it to be packaged in the plnkr source files where paths may be mangled
    ace.config.set "workerPath", "/vendor/ace/src-min/"
    ace.config.set "modePath", "/vendor/ace/src-min/"
    ace.config.set "themePath", "/vendor/ace/src-min/"
    
    aceEl = $el.find(".plunker-ace-canvas").get(0)
    
    $scope.session = session
    
    $scope.$watch "session.getActiveBuffer()", (buffer) ->
      ignoreCursorMove = true
      ctrl.editor.setSession(ctrl.sessions[buffer.id])
      ignoreCursorMove = false
      
      cursor.filename = buffer.filename
      
    $scope.$watch ( -> settings.editor.theme ), (theme) ->
      ctrl.editor.setTheme("ace/theme/#{theme}")
      
    $scope.$watch "cursor.filename", (filename) ->
      session.activateBuffer(filename) if filename and filename != session.getActiveBuffer().filename
    
    onChangeCursorPosition = ->
      current = ctrl.editor.getCursorPosition()
      position = cursor.position
      
      unless position.row is current.row and position.column is current.column
        $timeout ->
          ctrl.editor.moveCursorTo(position.row, position.column)
          ctrl.editor.focus()
    
    $scope.$watch "cursor.position.row", onChangeCursorPosition
    $scope.$watch "cursor.position.column", onChangeCursorPosition
      
    $scope.$on "resize", -> ctrl.editor.resize()
    
    ctrl.edit(aceEl)

    ctrl.editor.on "changeSelection", ->
      angular.copy ctrl.editor.getCursorPosition(), cursor.position unless ignoreCursorMove
]