#= require ./../../vendor/ace/src/ace
#= require ./../../vendor/ace/src/ext-language_tools
#= require ./../../vendor/ace/src/ext-searchbox

#= require ./../services/session
#= require ./../services/modes
#= require ./../services/settings
#= require ./../services/annotations
#= require ./../services/activity
#= require ./../services/participants
#= require ./../services/panes


module = angular.module "plunker.ace", [
  "plunker.session"
  "plunker.modes"
  "plunker.settings"
  "plunker.annotations"
  "plunker.activity"
  "plunker.participants"
  "plunker.panes"
]

Editor = require("ace/editor").Editor
Renderer = require("ace/virtual_renderer").VirtualRenderer

EditSession = require("ace/edit_session").EditSession
MultiSelect = require("ace/multi_select").MultiSelect
UndoManager = require("ace/undomanager").UndoManager
Range = require("ace/range").Range

require("ace/placeholder").PlaceHolder
snippetManager = ace.require("ace/snippets").snippetManager    


# Convert an ACE Range object row/col to an offset range

rangeToOffset = (doc, range) -> doc.positionToIndex(range.start)
rangeToInterval = (doc, range) -> [doc.positionToIndex(range.start), doc.positionToIndex(range.end)]


# Convert an offset range to an ace row/col range

offsetToRange = (doc, offset, length = 0) -> Range.fromPoints doc.indexToPosition(offset), doc.indexToPosition(offset + length)
offsetToPosition = (doc, offset) -> doc.indexToPosition(offset)

nextClass = do ->
  idx = -1
  -> idx = (idx + 1) % 20

module.directive "plunkerParticipant", ["session", "participants", (session, participants) ->
  restrict: "E"
  replace: true
  require: "^plunkerAce"
  scope:
    buffer: "="
    participant: "="
  template: """
    <div class="plunker-participant">
    </div>
  """
  
  link: ($scope, $el, attrs, controller) ->
    selectionMarkerRange = new Range(0, 0, 0, 0)
    selectionMarkerId = null
    
    cursorMarkerRange = new Range(0, 0, 0, 0)
    cursorMarkerId = null
    
    activeSession = null
    
    
    participant = $scope.participant
    participant.style = "participant-#{nextClass()}"

    cleanUp = -> if activeSession
      selectionMarkerRange.start.detach()
      selectionMarkerRange.end.detach()
      
      cursorMarkerRange.start.detach()
      cursorMarkerRange.end.detach()
      
      activeSession.removeMarker selectionMarkerId
      activeSession.removeMarker cursorMarkerId
      
      delete buffer.participants[participant.id] if buffer = session.buffers[participant.state.buffId]

    $scope.$watch "participant.state", (state, oldState) ->
      return unless state
      
      if !oldState or state.buffId != oldState.buffId
        cleanUp()
        
        if oldState and (buffer = session.buffers[oldState.buffId]) then delete buffer.participants[participant.id]
        if state and (buffer = session.buffers[state.buffId]) then buffer.participants[participant.id] = participant
        
        if activeSession = controller.sessions[state.buffId]
          doc = activeSession.getDocument()
          
          selectionMarkerRange.start = doc.createAnchor(state.selection.start.row, state.selection.start.column)
          selectionMarkerRange.end = doc.createAnchor(state.selection.end.row, state.selection.end.column)
          selectionMarkerId = activeSession.addMarker selectionMarkerRange, "participant-selection #{participant.style}", "text"
  
          cursorMarkerRange.start = doc.createAnchor(state.cursor.row, state.cursor.column)
          cursorMarkerRange.end = doc.createAnchor(state.cursor.row, state.cursor.column + 1)
          cursorMarkerId = activeSession.addMarker cursorMarkerRange, "participant-cursor #{participant.style}", "text"
      
      else if activeSession
        selectionMarkerRange.start.setPosition(state.selection.start.row, state.selection.start.column)
        selectionMarkerRange.end.setPosition(state.selection.end.row, state.selection.end.column)

        cursorMarkerRange.start.setPosition(state.cursor.row, state.cursor.column)
        cursorMarkerRange.end.setPosition(state.cursor.row, state.cursor.column + 1)
      
      if activeSession then activeSession._emit "changeBackMarker"
    , true
    
    # Trigger a cursor event in ace
    controller.sessions[controller.buffId]._emit "changeSelection"
    
    $scope.$on "$destroy", -> cleanUp()
]

module.directive "plunkerEditSession", ["$timeout", "modes", "settings", "annotations", "activity", ($timeout, modes, settings, annotations, activity) ->
  restrict: "E"
  replace: true
  require: ["ngModel", "^plunkerAce"]
  scope:
    buffer: "="
  template: """
    <div class="plunker-edit-session">
    </div>
  """
  
  link: ($scope, $el, attrs, [model, controller]) ->
    $scope.settings = settings.editor
    
    cleanup = []
    buffer = $scope.buffer
    
    session = new EditSession(model.$modelValue or "")
    session.setUndoManager(new UndoManager())
    session.setTabSize(settings.editor.tab_size)
    session.setUseWrapMode(!!settings.editor.wrap.enabled)
    session.setWrapLimitRange(settings.editor.wrap.range.min, settings.editor.wrap.range.max)
    session.setUseWorker(true)
    session.setNewLineMode("unix")
    
    
    doc = session.getDocument()


    # Register this session with the parent directive's controller
    controller.addSession(buffer.id, session)


    # Enable two-way binding between the session and ACE
    model.$render = ->  session.setValue(model.$modelValue)
    
    session.on "change", (delta) ->
      unless session.getValue() == model.$viewValue or $scope.$root.$$phase then $scope.$apply ->
        model.$setViewValue(session.getValue())
        controller.markDirty()
      
    # Create an entry for the file's annotations
    annotations[buffer.id] = []

    session.on "changeAnnotation", ->
      # Ignore changes in annotations that do not happen asynchronously
      unless $scope.$root.$$phase
        $scope.$apply ->
          annotations[buffer.id] = angular.copy session.getAnnotations()
          
    
    # Handle text events
    client = activity.client("ace")
    
    doc.on "change", (e) ->
      unless $scope.$root.$$phase
        nl = doc.getNewLineCharacter()
        
        switch e.data.action
          when "insertText" then client.record "insert", { buffId: buffer.id, offset: rangeToOffset(doc, e.data.range), text: e.data.text }
          when "removeText" then client.record "remove", { buffId: buffer.id, offset: rangeToOffset(doc, e.data.range), text: e.data.text }
          when "insertLines" then client.record "insert", { buffId: buffer.id, offset: rangeToOffset(doc, e.data.range), text: e.data.lines.join(nl) + nl }
          when "removeLines" then client.record "remove", { buffId: buffer.id, offset: rangeToOffset(doc, e.data.range), text: e.data.lines.join(nl) + nl }

    cleanup.push client.handleEvent "insert", (type, event) ->
      if event.buffId is buffer.id
        doc.insert offsetToPosition(doc, event.offset), event.text
      
    cleanup.push client.handleEvent "remove", (type, event) ->
      if event.buffId is buffer.id
        doc.remove offsetToRange(doc, event.offset, event.text.length)



    # Change the mode upon changes to the filename
    $scope.$watch "buffer.filename", (filename) ->
      mode = modes.findByFilename(filename)
      session.setMode("ace/mode/#{mode.name}")
      
      controller.markDirty()
    
    
    # Update the tab size and tab type upon changes to those settings
    $scope.$watch "settings.tab_size", (tab_size) ->
      session.setTabSize(tab_size)
      
    $scope.$watch "settings.soft_tabs", (soft_tabs) ->
      session.setUseSoftTabs(!!soft_tabs)
    
    $scope.$watch "settings.wrap.enabled", (wrapping) ->
      session.setUseWrapMode(!!wrapping)
    
    $scope.$watch "settings.wrap.range", (range) ->
      session.setWrapLimitRange(range.min, range.max)
    , true
    
    session.activate = ->
      if buffer.snippet && snippetManager
        $timeout ->
          session.setValue("")
          snippetManager.insertSnippet(controller.editor, buffer.snippet)
          controller.editor.focus()
          delete buffer.snippet

    # Handle clean-up
    $scope.$on "$destroy", ->
      controller.removeSession(buffer.id)
      
      deregister() for deregister in cleanup
      
      delete annotations[buffer.id]
]



module.directive "plunkerAce", ["$timeout", "$q", "session", "settings", "activity", "participants", ($timeout, $q, session, settings, activity, participants) ->
  restrict: "E"
  replace: true
  require: "plunkerAce"
  template: """
    <div class="plunker-ace">
      <plunker-edit-session ng-model="buffer.content" buffer="buffer" ng-repeat="(id, buffer) in session.buffers"></plunker-edit-session>
      <plunker-participant participant="participant" ng-repeat="(id, participant) in participants"></plunker-participant>
      <div class="plunker-ace-canvas"></div>
    </div>
  """
  controller: ["$scope", "panes", ($scope, panes) ->
    $scope.session = session
    $scope.settings = settings.editor
    $scope.participants = participants
  
    @sessions = {}
      
    @addSession = (buffId, session) -> @sessions[buffId] = session
    @removeSession = (buffId) -> delete @sessions[buffId]
    
    @activate = (@buffId) ->
      @editor.setSession(@sessions[@buffId])
      @sessions[@buffId].activate?()
    
    @markDirty = -> session.updated_at = Date.now()
    
    @loadModule = (modulePath) ->
      dfd = $q.defer()
      ace.config.loadModule modulePath, (module) -> dfd.resolve(module)
      dfd.promise
    
    @loadScript = (scriptUrl) ->
      dfd = $q.defer()
      require("ace/lib/net").loadScript scriptUrl, -> dfd.resolve(scriptUrl)
      dfd.promise
    
    @setupAutocomplete = ->
      @loadModule("ace/ext/language_tools").then =>
        @editor.setOptions
          enableBasicAutocompletion: true
          enableSnippets: true
      
      $q.all([@loadModule("ace/ext/emmet"), @loadScript("https://nightwing.github.io/emmet-core/emmet.js")]).then ([module]) =>
        module.setCore(window.emmet)
        @editor.setOption "enableEmmet", true

  
    @bindKeys = (keyboardHandler) ->
      if not keyboardHandler or keyboardHandler is "ace"
        @editor.setKeyboardHandler(null)
      else
        @editor.setKeyboardHandler("ace/keyboard/#{keyboardHandler}")

      @editor.commands.addCommand
        name: "Save"
        bindKey:
          win: "Ctrl-S"
          mac: "Command-S"
        exec: ->  $scope.$apply ->
          session.save() if session.isPlunkDirty()
      
      @editor.commands.addCommand
        name: "Preview"
        bindKey:
          win: "Ctrl-Return"
          mac: "Command-Return"
        exec: -> $scope.$apply ->
          panes.toggle(previewer) if previewer = panes.findById("preview")
      
      @editor.commands.addCommand
        name: "Next buffer"
        bindKey:
          win: "Ctrl-Down"
          mac: "Command-Down"
        exec: -> $scope.$apply ->
          session.switchBuffer(1)
      
      @editor.commands.addCommand
        name: "Previous buffer"
        bindKey:
          win: "Ctrl-Up"
          mac: "Command-Up"
        exec: -> $scope.$apply ->
          session.switchBuffer(-1)
          
    @
  ]
  link: ($scope, $el, attrs, controller) ->
    # Configure ACE to allow it to be packaged in the plnkr source files where paths may be mangled
    ace.config.set "basePath", "/vendor/ace/src-min/"
    
    $aceEl = $el.find(".plunker-ace-canvas").get(0)

    controller.editor = new Editor(new Renderer($aceEl, "ace/theme/#{settings.editor.theme || 'textmate'}"))

    controller.bindKeys(settings.editor.keyboard_handler)
    controller.setupAutocomplete()
    
    MultiSelect(controller.editor)
    
    controller.editor.on "changeSelection", ->
      unless $scope.$$phase
        selection = controller.editor.getSession().getSelection()
        
        activity.client("ace").record "selection",
          buffId: session.getActiveBuffer().id
          selection: angular.copy(selection.getRange())
          cursor: angular.copy(selection.getCursor())

        
    activity.client("ace").handleEvent "selection", (type, event) ->
      buffer = session.buffers[event.buffId]
      
      if buffer != session.getActiveBuffer()
        # Sometimes cursor events are in angular, sometimes out
        unless $scope.$root.$$phase then $scope.$apply -> session.activateBuffer(buffer)
        else session.activateBuffer(buffer)
        
        controller.activate(buffer.id)
        
      selection = controller.sessions[event.buffId].getSelection()
      
      if event.cursor
        selection.moveCursorToPosition(event.cursor)
      
      if event.selection
        selection.setSelectionRange(event.selection)
      else
        selection.clearSelection()
      
      controller.editor.focus()
    
    
    $scope.$watch "session.activeBuffer", (buffer, old) ->
      controller.activate(buffer.id)

      selection = controller.editor.getSession().getSelection()
      
      activity.client("ace").record "selection",
        buffId: buffer.id
        selection: angular.copy(selection.getRange())
        cursor: angular.copy(selection.getCursor())
    
    
    $scope.$watch "session.readonly", (readonly) ->
      controller.editor.setReadOnly(!!readonly)

    $scope.$watch "settings.font_size", (font_size) ->
      controller.editor.setFontSize(font_size)
    
    $scope.$watch "settings.theme", (theme) ->
      controller.editor.setTheme("ace/theme/#{theme}")
    
    $scope.$watch "settings.keyboard_handler", (keyboard_handler) ->
      controller.bindKeys(keyboard_handler)
    
    $scope.$on "resize", ->
      controller.editor.resize(true)

]
