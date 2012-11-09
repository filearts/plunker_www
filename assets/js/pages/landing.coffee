#= require ../services/plunks
#= require ../services/url

#= require ../directives/card
#= require ../directives/overlay

module = angular.module("plunker.landing", ["plunker.card", "plunker.plunks", "plunker.url", "plunker.overlay"])

module.config ["$routeProvider", "$locationProvider", ($routeProvider, $locationProvider) ->
  $routeProvider.when "/",
    templateUrl: "partials/explore.html"
    controller: ["$scope", "$timeout", "plunks", "url", ($scope, $timeout, plunks, url) ->
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
  $routeProvider.when "/:plunk_id",
    templateUrl: "partials/preview.html"
    resolve: do ->
      resolve =
        plunk: ($route, plunks) ->
          plunk = plunks.findOrCreate(id: $route.current.params.plunk_id)
          plunk.refresh()
      
      resolve.plunk.$inject = ["$route", "plunks"]
      
      resolve
    controller: ["$scope", "$routeParams", "plunks", ($scope, $routeParams, plunks) ->
      $scope.plunk = plunks.findOrCreate(id: $routeParams.plunk_id)
      
    ]
      
  $routeProvider.otherwise(templateUrl: "partials/explore.html", controller: "ExploreController")
  
  $locationProvider.html5Mode(true)
]
