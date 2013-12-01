require "../vendor/angular/angular"

require "./apps/landing.coffee"
require "./apps/editor.coffee"


module = angular.module "plunker", [
  "ui.router"
  
  "plunker.app.landing"
  "plunker.app.editor"
]

module.config ["$stateProvider", "$urlRouterProvider", "$locationProvider", ($stateProvider, $urlRouterProvider, $locationProvider) ->
  $locationProvider.html5Mode(true).hashPrefix('!')
  
  $urlRouterProvider.when "/edit", "/edit/"
  
  $urlRouterProvider.otherwise("/")
]


