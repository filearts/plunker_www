#= require ../services/plunks
#= require ../services/visitor

#= require ../directives/gallery
#= require ../directives/overlay
#= require ../directives/plunkinfo
#= require ../directives/timeago

module = angular.module "plunker.preview", [
  "plunker.plunks"
  "plunker.visitor"
  "plunker.gallery"
  "plunker.overlay"
  "plunker.plunkinfo"
  "plunker.timeago"
]


module.config ["$routeProvider", ($routeProvider) ->
  $routeProvider.when "/:plunk_id",
    templateUrl: "partials/preview.html"
    resolve:
      plunk: ["$route", "plunks", ($route, plunks) ->
        plunk = plunks.findOrCreate(id: $route.current.params.plunk_id)
        plunk.refresh() unless plunk.$$refreshed_at
        plunk
      ]
      
    controller: ["$scope", "$routeParams", "visitor", "plunk", ($scope, $routeParams, visitor, plunk) ->
      $scope.plunk = plunk
      $scope.visitor = visitor
    ]
]