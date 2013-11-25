#= require ./../services/panes

module = angular.module "plunker.multipane", [
  "plunker.panes"
]

module.directive "plunkerPane", [ "$compile", "panes", ($compile, panes) ->
  restrict: "E"
  replace: true
  scope:
    pane: "=usePane"
  template: """
    <div class="plunker-pane" ng-show="pane==panes.active"></div>
  """
  link: ($scope, $el, attrs) ->
    $scope.panes = panes
    
    pane = $scope.pane
    pane.$scope = $scope.$new()
    
    $child = $compile(pane.template or "")(pane.$scope)[0]
    $el.append($child)

    pane.link(pane.$scope, $child, attrs)
    
    $scope.$watch "pane.hidden", (hidden) ->
      panes.close(pane) if hidden and panes.active is pane
    
    $scope.$watch "pane==panes.active", (active) ->
      pane.active = active
]

module.directive "plunkerMultipane", [ "panes", (panes) ->
  restrict: "E"
  replace: true
  template: """
    <div class="plunker-multipane">
      <plunker-pane use-pane="pane" ng-repeat="pane in panes.panes"></plunker-pane>
    </div>
  """
  link: ($scope, $el, attrs) ->
    $scope.panes = panes
]