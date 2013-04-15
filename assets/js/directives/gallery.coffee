#= require ./../../vendor/masonry/jquery.masonry

#= require ./../directives/card

module = angular.module "plunker.gallery", ["plunker.card"]

module.directive "plunkerGallery", ["$timeout", "$location", ($timeout, $location) ->
  restrict: "E"
  replace: true
  scope:
    plunks: "="
  template: """
    <div class="plunker-gallery">
      <ul class="gallery">
        <li plunker-card ng-repeat="plunk in plunks" ng-animate="'fade'" plunk="plunk"></li>
      </ul>
    </div>
  """
  link: ($scope, $el, attrs) ->
    nextRefresh = null
    
    $gallery = $(".gallery", $el)
    
    (refreshInterval = ->
      if nextRefresh
        $scope.plunks.refresh()  
        $timeout.cancel(nextRefresh)
      
      nextRefresh = $timeout refreshInterval, 60 * 1000
    )()
    
    $gallery.masonry columnWidth: 300
    
    
    $scope.$watch "plunks.$$refreshed_at", ->
      $timeout -> $gallery.masonry "reload"
    
    $scope.$on "$destroy", -> $timeout.cancel(nextRefresh)
]