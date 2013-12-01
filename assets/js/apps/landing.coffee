fs = require("fs")

require "../../vendor/angular/angular"
require "../../vendor/angular-deckgrid/angular-deckgrid"

require "../services/api.coffee"
require "../services/url.coffee"


module = angular.module "plunker.app.landing", [
  "ui.router"
  "akoenig.deckgrid"
  
  "plunker.service.api"
  "plunker.service.url"
]

module.config ["$stateProvider", "$urlRouterProvider", ($stateProvider, $urlRouterProvider) ->
  $stateProvider.state "home",
    url: "/"
    templateUrl: "/partials/landing.html"
    controller: ["$scope", "api", ($scope, api) ->
      $scope.plunks = []
      
      api.all("plunks").allUrl("plunks", "trending").getList().then (plunks) ->
        angular.copy plunks, $scope.plunks
    ]

  $stateProvider.state "view",
    url: "/:plunkId"
    templateUrl: "/partials/card.html"
    resolve:
      plunk: ["$stateParams", "api", ($stateParams, api) ->
        api.all("plunks").one($stateParams.plunkId).get()
      ]
    controller: ["$scope", "$sce", "plunk", "url", ($scope, $sce, plunk, url) ->
      $scope.viewUrl = $sce.trustAsResourceUrl(plunk.raw_url)
      $scope.plunk = plunk
    ]
]