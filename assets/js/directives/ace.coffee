#= require ../../vendor/ace/src/ace

#= require ../services/session
#= require ../services/modes
#= require ../services/settings
#= require ../services/annotations
#= require ../services/activity
#= require ../services/guard


module = angular.module "plunker.ace", [
  "plunker.session"
  "plunker.modes"
  "plunker.settings"
  "plunker.annotations"
  "plunker.activity"
  "plunker.cursor"
  "plunker.guard"
]


module.directive "plunkerEditSession", [ "$timeout", "modes", "session", "settings", "annotations", "activity", ($timeout, modes, editsession, settings, annotations, activity) ->
  EditSession = require("ace/edit_session").EditSession
  UndoManager = require("ace/undomanager").UndoManager
  Range = require("ace/range").Range
  
  
  rangeToOffset = (doc, range) ->
    lines = doc.getLines 0, range.start.row
      
    offset = 0

    for line, i in lines
      if i < range.start.row then offset += line.length
      else offset += range.start.column

    # Add the row number to include newlines.
    offset + range.start.row
    
  offsetToRange = (doc, offset, length = 0) ->
    # Again, very inefficient.
    lines = doc.getAllLines()

    row = 0
    for line, row in lines
      if offset <= line.length
        unless start
          start = row: row, column: offset
          offset += length
      if offset <= line.length
        if start
          end = row: row, column: offset
          break

      # +1 for the newline.
      offset -= lines[row].length + 1
    
    new Range(start.row, start.column, end.row, end.column)
  
  
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
    
    session = new EditSession(model.$modelValue or "")
    session.setUndoManager(new UndoManager())
    session.setTabSize(settings.editor.tab_size)
    session.setUseWorker(true)
    
    doc = session.getDocument()
    cleanup = []
    
    $timeout -> initial = false
    
    updateModel = (fn) ->
      if !initial and !$scope.$root.$$phase then $scope.$apply(fn)
      else fn()
    
    model.$render = -> 
      session.setValue(model.$modelValue)
    
    session.on "change", (delta) ->
      updateModel -> model.$setViewValue(session.getValue())
      
    session.on "changeAnnotation", ->
      updateModel -> annotations[buffer.id] = angular.copy session.getAnnotations(), 

    $scope.$watch "buffer.filename", (filename) ->
      mode = modes.findByFilename(filename)
      session.setMode("ace/mode/#{mode.name}")
      editsession.updated_at = Date.now()
    
    $scope.$watch "buffer.content", (content) ->
      editsession.updated_at = Date.now()
      
    doc.on "change", (e) ->
      return if initial
      
      $scope.$apply ->
        switch e.data.action
          when "insertText" then activity.record "insert", ["files", buffer.id, "content", rangeToOffset(doc, e.data.range)], e.data.text
          when "removeText" then activity.record "remove", ["files", buffer.id, "content", rangeToOffset(doc, e.data.range)], e.data.text
          when "insertLines" then activity.record "insert", ["files", buffer.id, "content", rangeToOffset(doc, e.data.range)], e.data.lines.join("\n") + "\n"
          when "removeLines" then activity.record "remove", ["files", buffer.id, "content", rangeToOffset(doc, e.data.range)], e.data.lines.join("\n") + "\n"
    
    
    cleanup.push activity.addHandler "insert", (path, text) ->
      [ignore0, buffId, ignore1, offset] = path
      
      
      if buffId is buffer.id
        doc.insert offsetToRange(doc, offset).start, text
      
    cleanup.push activity.addHandler "remove", (path, text) ->
      [ignore0, buffId, ignore1, offset] = path
      
      if buffId is buffer.id
        doc.remove offsetToRange(doc, offset, text.length)
      
    $scope.$watch ( -> settings.editor.tab_size ), (tab_size) ->
      session.setTabSize(tab_size)
    
    $scope.$watch ( -> settings.editor.soft_tabs ), (soft_tabs) ->
      session.setUseSoftTabs(!!soft_tabs)
      
    aceEditor.sessions[buffer.id] = session

    annotations[buffer.id] = []
    
    console.log "Creating session", buffer.id, buffer
    
    $scope.$on "$destroy", ->
      console.log "Destroying session", buffer.id, buffer
      delete aceEditor.sessions[buffer.id]
      delete annotations[buffer.id]
      
      unregister() for unregister in cleanup
]

module.directive "plunkerAce", [ "$timeout", "session", "settings", "activity", "visitor", "cursor", "guard", ($timeout, session, settings, activity, visitor, cursor, guard) ->
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
      console.log "Creating ace controller"
      @sessions = {}
      @editor = null

    edit: (@el) ->
      @editor = new Editor(new Renderer(@el, "ace/theme/textmate"))
        
  link: ($scope, $el, attrs, [ctrl, model]) ->
    # Configure ACE to allow it to be packaged in the plnkr source files where paths may be mangled
    ace.config.set "workerPath", "/vendor/ace/src-min/"
    ace.config.set "modePath", "/vendor/ace/src-min/"
    ace.config.set "themePath", "/vendor/ace/src-min/"
    
    aceEl = $el.find(".plunker-ace-canvas").get(0)
    
    $scope.session = session
    $scope.cursor = cursor
    
    ignoreCursorMove = false
    
    bufferGuard = guard($scope, "cursor.buffer")
    cursorGuard = guard($scope, "cursor.position")
    
    $scope.$watch "session.getActiveBuffer()", (buffer) ->
      #ignoreCursorMove = true
      ctrl.editor.setSession(ctrl.sessions[buffer.id])
      
      # When the active file changes, update the cursor after the fact to reflect
      # the final position
      bufferGuard.setViewValue(buffer.id)
      #cursorGuard.setViewValue(ctrl.editor.getCursorPosition())

      #ignoreCursorMove = false
            
    $scope.$watch ( -> settings.editor.theme ), (theme) ->
      ctrl.editor.setTheme("ace/theme/#{theme}")
      
    #
    # Interface with activity stream
    #
    
    # Write to the activity stream
    $scope.$watch "cursor.buffer", (buffId) ->
      if buffer = session.buffers[buffId]
        activity.record "session.buffer", ["sessions", visitor.session.public_id, "buffer"], buffer.id
      
    $scope.$watch "cursor.position", (position) ->
      activity.record "session.cursor", ["sessions", visitor.session.public_id, "cursor"], position
    , true
    
    # Read from the activity stream (handle events)
    activity.addHandler "reset", (path, options) ->
      session.reset(options, soft: true)

    # Read from the activity stream (handle events)
    activity.addHandler "files.add", (path, buffer) ->
      session.addBuffer(buffer.filename, buffer.content, buffer)


    # Read from the activity stream (handle events)
    activity.addHandler "files.remove", (path, buffer) ->
      session.removeBuffer(buffer.filename)

    activity.addHandler "session.buffer", (path, buffId) ->
      cursor.buffer = buffId
    
    activity.addHandler "session.cursor", (path, position) ->
      cursor.position = angular.copy(position)
    
    # When an external change requires the buffer to change
    bufferGuard.render = ->
      if buffer = session.buffers[bufferGuard.modelValue]
        session.activateBuffer(buffer.filename)

    # When an external change requires the cursor to move
    cursorGuard.render = ->
      position = cursorGuard.modelValue
      
      $timeout ->
        ctrl.editor.gotoLine(position.row + 1, position.column)
        ctrl.editor.focus()

    $scope.$on "resize", -> $timeout -> ctrl.editor.resize()
    
    ctrl.edit(aceEl)

    ctrl.editor.on "changeSelection", ->
      unless ignoreCursorMove or $scope.$$phase then $scope.$apply ->
        cursorGuard.setViewValue(ctrl.editor.getCursorPosition())
]