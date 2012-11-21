#= require ../services/plunks
#= require ../services/url

#= require ../directives/card

module = angular.module "plunker.gallery", ["plunker.plunks", "plunker.url", "plunker.card"]

module.directive "plunkerGallery", ["$timeout", "plunks", "url", ($timeout, plunks, url) ->
  restrict: "E"
  replace: true
  template: """
    <div class="plunker-gallery">
      <ul class="nav nav-pills">
        <li ng-repeat="filter in filters" ng-class="{active: filter == activeFilter}">
          <a ng-href="javascript:void(0)" ng-click="setFilter(filter)" ng-bind="filter.text"></a>
        </li>
      </ul>
      
      <ul class="gallery">
        <li plunker-card ng-repeat="plunk in plunks | orderBy:activeFilter.sort:true" plunk="plunk"></li>
      </ul>
    </div>
  """
  link: ($scope, $el, attrs) ->
    $scope.filters = [
      href: "/trending"
      text: "Trending"
      source: "/trending"
      sort: "score"
    ,
      href: "/popular"
      text: "Popular"
      source: "/popular"
      sort: "thumbs"
    ,
      href: "/"
      text: "Recent"
      source: ""
      sort: "updated_at"
    ]
    
    $scope.activeFilter = $scope.filters[0]
    $scope.setFilter = (filter) -> $scope.activeFilter = filter
    
    $scope.plunks = plunks.query(url: "#{url.api}/plunks#{$scope.activeFilter.source}")
    
    $scope.$watch "activeFilter.source", (source) ->
      source = "#{url.api}/plunks#{source}"
      $scope.plunks = plunks.query(url: source) unless source == $scope.plunks.url
    
    nextRefresh = null
    
    (refreshInterval = ->
      $scope.plunks.refresh()
      
      nextRefresh = $timeout refreshInterval, 60 * 1000
    )()
    
    $scope.$on "$destroy", -> $timeout.cancel(nextRefresh)
]