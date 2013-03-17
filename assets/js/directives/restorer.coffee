#= require ./../../vendor/bootstrap/js/bootstrap-alert.js

#= require ./../services/session


module = angular.module "plunker.restorer", [
  "plunker.session"
]

module.directive "plunkerRestorer", [ "session", (session) ->
  restrict: "E"
  replace: true
  scope: true
  template: """
    <div class="alert alert-info plunker-restorer" ng-show="savedState">
      <p><strong>Unsaved session</strong> Restore your previous session?</p>
      <button class="btn btn-success btn-mini" ng-click="restoreSession()">Restore</button>
      <button class="btn btn-danger btn-mini" data-dismiss="alert">Discard</button>
    </div>
  """
  link: ($scope, $el, attrs) ->
    $($el).alert
      close: -> window.localStorage.removeItem("plnkr_dirty_state")
        
    $scope.restoreSession = ->
      session.reset($scope.savedState, dirty: true)
      window.localStorage.removeItem("plnkr_dirty_state")
      $($el).alert("close")
    
    $scope.savedState = session.lastSession

]