#= require "../services/session"
#= require "../services/notifier"


module = angular.module "plunker.sidebar", ["plunker.session", "plunker.notifier"]

module.directive "plunkerSidebarFile", [ "notifier", "session", (notifier, session) ->
  restrict: "E"
  replace: true
  scope:
    buffer: "="
  template: """
    <li class="file" ng-class="{active: active}">
      <a ng-click="activateBuffer(buffer)">{{buffer.filename}}</a>
      <ul class="file-ops">
        <li class="delete">
          <button ng-click="promptFileDelete(buffer)" class="btn btn-mini">
            <i class="icon-remove"></i>
          </button>
        </li>
      </ul>
    </li>
  """
  link: ($scope, $el, attrs) ->
    #$scope.session = session
    
    buffer = $scope.buffer
    
    $scope.$watch ( -> session.getActiveBuffer() == buffer), (active) ->
      $scope.active = active
    
    $scope.activateBuffer = (buffer) ->
      session.activateBuffer(buffer.filename)
    
    $scope.promptFileDelete = (buffer) ->
      notifier.confirm "Confirm Delete", "Are you sure that you would like to delete #{buffer.filename}?",
        confirm: -> session.removeBuffer(buffer.filename)
]

module.directive "plunkerSidebar", [ "session", (session) ->
  restrict: "E"
  replace: true
  template: """
    <div class="plunker-sidebar">
      <details open>
        <summary class="header">Files</summary>
        <ul class="plunker-filelist nav nav-list">
          <plunker-sidebar-file buffer="buffer" ng-repeat="(id, buffer) in session.buffers">
            <a ng-click="session.activateBuffer(buffer.filename)">{{buffer.filename}}</a>
          </plunker-sidebar-file>
        </ul>
      </details>
    </div>
  """
  link: ($scope, $el, attrs) ->
    $scope.session = session

]