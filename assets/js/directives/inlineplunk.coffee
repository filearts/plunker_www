#= require ../services/quickview

module = angular.module "plunker.inlineplunk", ["plunker.quickview"]

module.directive "plunkerInlinePlunk", [ "$rootScope", "quickview", ($rootScope, quickview) ->
  restrict: "E"
  scope:
    plunk: "="
  transclude: true
  replace: true
  template: """
    <span class="inline-plunk" ng-class="{owned: plunk.isOwned()}">
      <a ng-href="{{plunk.id}}" ng-click="showQuickView(plunk, $event)" ng-transclude>
      </a>
    </span>
  """
  link: ($scope, $el, attrs) ->
    $scope.$watch "plunk", (plunk) ->
      if plunk
        plunk.refresh() unless plunk.$$refreshing or plunk.$$refreshed_at
    
    $scope.showQuickView = (plunk, $event) ->
      quickview.show(plunk)
      
      $event.preventDefault()
      $event.stopPropagation()
]