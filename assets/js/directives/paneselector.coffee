#= require ./../../vendor/ui-bootstrap/ui-bootstrap-tpls-0.3.0

#= require ./../services/panes

module = angular.module "plunker.paneselector", [
  "plunker.panes"
  "ui.bootstrap"
  "ui.bootstrap.tooltip"
]

module.directive "plunkerPaneselector", [ "panes", (panes) ->
  restrict: "E"
  replace: true
  template: """
    <div class="plunker-paneselector">
      <ul>
        <li tooltip="{{pane.title}}" tooltip-placement="left" ng-repeat="pane in panes.panes | orderBy:'order'" class="{{pane.class}} plunker-pane-{{pane.id}}" ng-hide="pane.hidden" ng-class="{active:pane==panes.active}">
          <a ng-click="panes.toggle(pane) | trackEvent:'Multipane':'Toggle':pane.title">
            <i class="icon-{{pane.icon}}"></i>
          </a>
        </li>
      </ul>
    </div>
  """
  link: ($scope, $el, attrs) ->
    $scope.panes = panes
]