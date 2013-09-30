genid = require("genid")
debounce = require("lodash.debounce")

require "../../vendor/operative.js"

require "../services/session.coffee"
require "../services/types.coffee"
require "../services/url.coffee"
require "../services/settings.coffee"
require "../services/annotations.coffee"

module = angular.module "plunker.directive.previewer", [
  "plunker.service.session"
  "plunker.service.url"
  "plunker.service.settings"
  "plunker.service.annotations"
]

module.directive "previewer", [ "$timeout", "session", "url", "settings", "annotations", ($timeout, session, url, settings, annotations) ->
  restrict: "E"
  replace: true
  scope:
    session: "="
  template: """
    <div>
      <div class="plunker-preview-container" ng-class="{message: message}">
        <iframe name="plunkerPreviewTarget" src="about:blank" width="100%" height="100%" frameborder="0"></iframe>
      </div>
      <div class="plunker-preview-message alert alert-danger" ng-show="message">
        <button type="button" class="close" ng-click="message=''" aria-hidden="true">&times;</button>
        <span ng-bind="message"></span>
      </div>
    </div>
  """
  link: ($scope, $el, attrs) ->
    $scope.previewUrl ||= "#{url.run}/#{genid()}/"
    
    client = session.createClient("previewer")
    
    refresh = (snapshot) -> $scope.$apply ->
      return if $scope.mode is "disabled"
      
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
    
    
    
    $scope.$watch ( -> settings.previewer.delay), (delay) ->
      refresh = debounce refresh, delay
      
    client.on "reset", (e, snapshot) -> refresh(snapshot)

    client.on "fileCreate", (e, snapshot) -> refresh(snapshot)
    client.on "fileRename", (e, snapshot) -> refresh(snapshot)
    client.on "fileRemove", (e, snapshot) -> refresh(snapshot)

    client.on "textInsert", (e, snapshot) -> refresh(snapshot)
    client.on "textRemove", (e, snapshot) -> refresh(snapshot)
    
    $timeout -> refresh(client.getSnapshot())
]