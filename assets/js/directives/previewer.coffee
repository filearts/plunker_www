genid = require("genid")
debounce = require("lodash.debounce")

require "../services/session.coffee"
require "../services/types.coffee"
require "../services/url.coffee"
require "../services/settings.coffee"
require "../services/annotations.coffee"
require "../services/layout.coffee"
require "../services/disabler.coffee"
require "../services/debounce.js"


module = angular.module "plunker.directive.previewer", [
  "plunker.service.session"
  "plunker.service.url"
  "plunker.service.settings"
  "plunker.service.annotations"
  "plunker.service.layout"
  "plunker.service.disabler"
  "plunker.service.debounce"
]

module.directive "previewer", [ "$timeout", "$state", "session", "url", "settings", "annotations", "layout", "disabler", "debounce", ($timeout, $state, session, url, settings, annotations, layout, disabler, debounce) ->
  restrict: "E"
  replace: true
  scope:
    session: "="
  template: """
    <div>
      <div class="plunker-preview-container" ng-class="{message: message}" plunker-disabler="previewer">
        <iframe id="plunkerPreviewTarget" name="plunkerPreviewTarget" src="about:blank" width="100%" height="100%" frameborder="0"></iframe>
      </div>
      <div class="plunker-preview-message alert alert-danger" ng-show="message">
        <button type="button" class="close" ng-click="message=''" aria-hidden="true">&times;</button>
        <span ng-bind="message"></span>
      </div>
    </div>
  """
  link: ($scope, $el, attrs) ->
    $scope.previewUrl ||= "#{url.run}/#{genid()}/"
    
    iframeEl = document.getElementById("plunkerPreviewTarget")
    listening = false
    client = session.createClient("previewer")
                               
    refresh = () ->
      return unless $state.includes("editor.new") or $state.includes("editor.plunk")
                               
      snapshot = client.getSnapshot()
      
      form = document.createElement("form")
      form.style.display = "none"
      form.setAttribute "method", "post"
      form.setAttribute "action", $scope.previewUrl
      form.setAttribute "target", "plunkerPreviewTarget"
      
      for file in snapshot.files
        field = document.createElement("input")
        field.setAttribute "type", "hidden"
        field.setAttribute "name", "files[#{file.filename}][content]"
        field.setAttribute "value", file.content
        
        form.appendChild(field)
      
      document.body.appendChild(form)
      
      form.submit()
      
      document.body.removeChild(form)
    
    debouncedRefresh = debounce refresh, settings.previewer.delay
    
    addListeners = ->
      client.on "reset", debouncedRefresh
  
      client.on "fileCreate", debouncedRefresh
      client.on "fileRename", debouncedRefresh
      client.on "fileRemove", debouncedRefresh
  
      client.on "textInsert", debouncedRefresh
      client.on "textRemove", debouncedRefresh
      
      listening = true
    
    removeListeners = ->
      client.off "reset", debouncedRefresh
  
      client.off "fileCreate", debouncedRefresh
      client.off "fileRename", debouncedRefresh
      client.off "fileRemove", debouncedRefresh
  
      client.off "textInsert", debouncedRefresh
      client.off "textRemove", debouncedRefresh
      
      listening = false
    
    enable = ->
      refresh()
      addListeners()
    
    disable = ->
      iframeEl.contentWindow.location = "about:blank"
      removeListeners()
      
    
    $scope.$on "$stateChangeSuccess", ->
      if $state.includes("editor.new") or $state.includes("editor.plunk")
        enable() unless listening
      else
        disable()
        
      
    
    $scope.$watch ( -> settings.previewer.delay), (delay, oldDelay) ->
      if delay != oldDelay
        debouncedRefresh.setWait(delay)

    $scope.$watch ( -> layout.current.preview.closed), (closed, wasClosed) ->
      if closed then disable()
      else enable()
]