#= require ../../vendor/ace/src/ace

#= require ../services/session
#= require ../services/modes

module = angular.module "plunker.ace", ["plunker.session", "plunker.modes"]

module.directive "plunkerEditSession", [ "modes", (modes) ->
  EditSession = require("ace/edit_session").EditSession
  UndoManager = require("ace/undomanager").UndoManager
  
  
  restrict: "E"
  replace: true
  require: ["?ngModel", "^plunkerAce"]
  scope:
    buffer: "="
  template: """
    <div class="plunker-edit-session">
    </div>
  """
  link: ($scope, $el, attrs, [model, aceEditor]) ->
    session = new EditSession(model.$modelValue)
    session.setUndoManager(new UndoManager())
    session.setTabSize(2)
    #session.setUseWrapMode(true)
    
    session.on "change", (delta) ->
      model.$setViewValue(session.getValue())
    
    model.$render = ->
      session.setValue(model.$modelValue)
    
    $scope.$watch "buffer.filename", (filename) ->
      mode = modes.findByFilename(filename)
      session.setMode("ace/mode/#{mode.name}")
    
    $scope.buffer.session = session
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