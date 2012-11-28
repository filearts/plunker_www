#= require ../services/plunks

#= require ../directives/gallery
#= require ../directives/overlay
#= require ../directives/plunkinfo
#= require ../directives/timeago

module = angular.module("plunker.preview", ["plunker.plunks", "plunker.gallery", "plunker.overlay", "plunker.plunkinfo", "plunker.timeago"])


module.config ["$routeProvider", ($routeProvider) ->
  $routeProvider.when "/:plunk_id",
    templateUrl: "partials/preview.html"
    resolve:
      plunk: ["$route", "plunks", ($route, plunks) ->
        plunk = plunks.findOrCreate(id: $route.current.params.plunk_id)
        plunk.refresh()
      ]
      
    controller: ["$scope", "$routeParams", "plunks", ($scope, $routeParams, plunks) ->
      $scope.plunk = plunks.findOrCreate(id: $routeParams.plunk_id)
      
    ]
]