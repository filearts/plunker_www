#= require ../services/panes

module = angular.module "plunker.paneselector", [
  "plunker.panes"
]

module.directive "plunkerPaneselector", [ "panes", (panes) ->
  restrict: "E"
  replace: true
  template: """
    <div class="plunker-paneselector">
      <ul>
        <li ng-repeat="pane in panes.panes | orderBy:'order'" class="{{pane.class}} plunker-pane-{{pane.id}}" ng-class="{active:pane==panes.active}">
          <a ng-click="panes.toggle(pane)" title="{{pane.title}}">
            <i class="icon-{{pane.icon}}"></i>
          </a>
        </li>
      </ul>
    </div>
  """
  link: ($scope, $el, attrs) ->
    $scope.panes = panes
]