require "../../vendor/angular/angular"
require "../../vendor/angular/angular-cookies"
require "../../vendor/angular-ui/ui-bootstrap"
require "../../vendor/angular-ui/ui-router"


module = angular.module "plunker.app.editor", [
  "ui.bootstrap"
  "ui.router"
  
  "fa.borderLayout"
]

module.config ["$urlRouterProvider", "$locationProvider", ($urlRouterProvider, $locationProvider) ->
  $locationProvider.html5Mode(true).hashPrefix('!')
  
  $urlRouterProvider.when "/edit", "/edit/"
  
  $urlRouterProvider.otherwise("/")
]

module.service "plunk", [ ->
  id: null
  import: 
]

module.config ["$stateProvider", ($stateProvider) ->
  $stateProvider.state "editor",
    url: "/edit"
    templateUrl: "/partials/editor.html"
  
  
  $stateProvider.state "editor.reset",
    controller: ["$state", "project", ($state, project) ->
      project.reset()
      
      $state.go "editor.edit"
  
  $stateProvider.state "editor.edit"
    controller: ["$state", "project", "initial", ($state, project, initial) ->
      project.