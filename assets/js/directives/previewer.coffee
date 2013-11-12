genid = require("genid")
debounce = require("lodash.debounce")

require "../../vendor/operative.js"

require "../services/session.coffee"
require "../services/types.coffee"
require "../services/url.coffee"
require "../services/settings.coffee"
require "../services/annotations.coffee"
require "../services/layout.coffee"
require "../services/disabler.coffee"


module = angular.module "plunker.directive.previewer", [
  "plunker.service.session"
  "plunker.service.url"
  "plunker.service.settings"
  "plunker.service.annotations"
  "plunker.service.layout"
  "plunker.service.disabler"
]

module.directive "previewer", [ "$timeout", "session", "url", "settings", "annotations", "layout", "disabler", ($timeout, session, url, settings, annotations, layout, disabler) ->
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
    
    client = session.createClient("previewer")
    firstOpen = true
    
    refresh = (snapshot) ->
      return if layout.current.preview.closed
      
      if filename = annotations.hasError()
        $scope.message = "Preview has not been updated due to syntax errors in #{filename}"
        return
      else
        $scope.message = ""
      
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
    
    applyRefresh = -> $scope.$apply -> refresh(client.getSnapshot())
    debouncedApplyRefresh = debounce applyRefresh, settings.previewer.delay
    
    $scope.$watch ( -> settings.previewer.delay), (delay, oldDelay) ->
      if delay != oldDelay
        debouncedApplyRefresh = debounce debouncedApplyRefresh, delay

    $scope.$watch ( -> layout.current.preview.closed), (closed, wasClosed) ->
      if closed
        iframeEl.contentWindow.location = "about:blank"
      else if firstOpen or wasClosed
        refresh(client.getSnapshot())
      
      firstOpen = false
    
    client.on "reset", debouncedApplyRefresh

    client.on "fileCreate", debouncedApplyRefresh
    client.on "fileRename", debouncedApplyRefresh
    client.on "fileRemove", debouncedApplyRefresh

    client.on "textInsert", debouncedApplyRefresh
    client.on "textRemove", debouncedApplyRefresh
    
    $scope.$on "$destroy", ->
      client.off "reset", debouncedApplyRefresh
  
      client.off "fileCreate", debouncedApplyRefresh
      client.off "fileRename", debouncedApplyRefresh
      client.off "fileRemove", debouncedApplyRefresh
  
      client.off "textInsert", debouncedApplyRefresh
      client.off "textRemove", debouncedApplyRefresh
]