#= require ../../vendor/angular

#= require ../controllers/landing
#= require ../controllers/preview

#= require ../services/menu


module = angular.module("plunker.landingPage", ["plunker.landing", "plunker.preview", "plunker.menu"])




module.config ["$locationProvider", ($locationProvider) ->
  $locationProvider.addIgnorePattern(/\/edit\//)
  $locationProvider.html5Mode(true)
]

module.run ["$rootScope", "menu", ($rootScope, menu) ->
  $rootScope[k] = v for k, v of _plunker
  $rootScope.menu = menu
]