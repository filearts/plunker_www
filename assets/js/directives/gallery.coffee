#= require ../directives/card

module = angular.module "plunker.gallery", ["plunker.card"]

module.directive "plunkerGallery", ["$timeout", ($timeout) ->
  restrict: "E"
  replace: true
  scope:
    plunks: "="
  template: """
    <div class="plunker-gallery">
      <ul class="gallery">
        <li plunker-card ng-repeat="plunk in plunks | orderBy:activeFilter.sort:true" plunk="plunk"></li>
      </ul>
    </div>
  """
  link: ($scope, $el, attrs) ->
    nextRefresh = null
    
    (refreshInterval = ->
      $scope.plunks.refresh()
      
      nextRefresh = $timeout refreshInterval, 60 * 1000
    )()
    
    $scope.$on "$destroy", -> $timeout.cancel(nextRefresh)
]