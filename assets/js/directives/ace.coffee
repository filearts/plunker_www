#= require ../../vendor/ace/src/ace

#= require ../services/session
#= require ../services/modes

module = angular.module "plunker.ace", ["plunker.session", "plunker.modes"]

module.directive "plunkerEditSession", [ "modes", "session", (modes, editsession) ->
  EditSession = require("ace/edit_session").EditSession
  UndoManager = require("ace/undomanager").UndoManager
  
  
  restrict: "E"
  replace: true
  require: ["?ngModel", "^plunkerAce"]
  scope:
    buffer: "="
  template: """
    <div class="plunker-edit-session" ng-bind="buffer.content">
    </div>
  """
  link: ($scope, $el, attrs, [model, aceEditor]) ->
    buffer = $scope.buffer
    initial = true
    
    session = new EditSession(model.$modelValue)
    session.setUndoManager(new UndoManager())
    session.setTabSize(2)
    session.setUseWorker(true)
    
    model.$render = -> 
      session.setValue(model.$modelValue)
      initial = false
    
    session.on "change", (delta) ->
      unless initial then $scope.$apply -> model.$setViewValue(session.getValue())
      
    session.on "changeAnnotation", ->
      angular.copy session.getAnnotations(), buffer.annotations

    $scope.$watch "buffer.filename", (filename) ->
      mode = modes.findByFilename(filename)
      session.setMode("ace/mode/#{mode.name}")
      editsession.updated_at = Date.now()
    
    $scope.$watch "buffer.content", (content) ->
      editsession.updated_at = Date.now()
    
    buffer.annotations = []
    buffer.session = session
]

module.directive "plunkerAce", [ "$timeout", "session", ($timeout, session) ->
  Editor = require("ace/editor").Editor
  Renderer = require("ace/virtual_renderer").VirtualRenderer
  

  restrict: "E"
  require: "plunkerAce"
  replace: true
  template: """
    <div class="plunker-ace">
      <plunker-edit-session ng-model="buffer.content" buffer="buffer" ng-repeat="(id, buffer) in session.buffers">
      </plunker-edit-session>
      <div class="plunker-ace-canvas"></div>
    </div>
  """
  controller: class AceController
    edit: (@el) ->
      @editor = new Editor(new Renderer(@el, "ace/theme/textmate"))
  
  link: ($scope, $el, attrs, ctrl) ->
    # Configure ACE to allow it to be packaged in the plnkr source files where paths may be mangled
    ace.config.set "workerPath", "/vendor/ace/src/"
    ace.config.set "modePath", "/vendor/ace/src/"
    ace.config.set "themePath", "/vendor/ace/src/"
    
    aceEl = $el.find(".plunker-ace-canvas").get(0)
    
    $scope.session = session
    
    $scope.$watch "session.getActiveBuffer()", (buffer) ->
      ctrl.editor.setSession(buffer.session)
      
    $scope.$on "resize", -> ctrl.editor.resize()
    
    ctrl.edit(aceEl)
]