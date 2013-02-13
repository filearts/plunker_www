#= require ../../vendor/angular-ui/common/module
#= require ../../vendor/angular-ui/modules/directives/jq/jq

#= require ../../vendor/bootstrap/js/bootstrap-tooltip
#= require ../../vendor/bootstrap/js/bootstrap-popover

#= require ../services/panes

module = angular.module "plunker.paneselector", [
  "plunker.panes"
  "ui.directives"
]

module.directive "plunkerPaneselector", [ "panes", (panes) ->
  restrict: "E"
  replace: true
  template: """
    <div class="plunker-paneselector">
      <ul>
        <li ng-repeat="pane in panes.panes | orderBy:'order'" class="{{pane.class}} plunker-pane-{{pane.id}}" ng-hide="pane.hidden" ng-class="{active:pane==panes.active}">
          <a ui-jq="popover" ui-options="{placement: 'left', title: pane.title, content: pane.description, trigger: 'hover'}" ng-click="panes.toggle(pane)">
            <i class="icon-{{pane.icon}}"></i>
          </a>
        </li>
      </ul>
    </div>
  """
  link: ($scope, $el, attrs) ->
    $scope.panes = panes
]