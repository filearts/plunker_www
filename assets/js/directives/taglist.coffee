require "../directives/stopPropagation.coffee"


module = angular.module "plunker.directive.taglist", [
  "plunker.directive.stopPropagation"
]

module.directive "plunkerTaglist", ->
  restrict: "E"
  replace: true
  scope:
    tags: "="
  template: """
    <ul class="plunker-taglist">
      <li ng-repeat="tag in tags"><a stop-propagation="click" ng-bind="tag"></a></li>
    </ul>
  """