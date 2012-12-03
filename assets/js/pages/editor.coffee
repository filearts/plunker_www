#= require ../../vendor/angular.js

#= require ../services/importer
#= require ../services/session
#= require ../services/notifier

#= require ../directives/userpanel
#= require ../directives/toolbar
#= require ../directives/overlay
#= require ../directives/layout

module = angular.module "plunker.editorPage", [
  "plunker.userpanel"
  "plunker.toolbar"
  "plunker.overlay"
  "plunker.layout"
  "plunker.importer"
  "plunker.session"
  "plunker.notifier"
]


module.config ["$locationProvider", ($locationProvider) ->
  $locationProvider.html5Mode(true)
]

module.config ["$routeProvider", ($routeProvider) ->
  $routeProvider.when "/:source",
    template: "<div></div>"
    resolve: 
      source: ["$route", "importer", "session", "notifier", ($route, importer, session, notifier) ->
        if source = $route.current.params.source
          unless source and source is session.getEditPath()
            importer.import(source).then (json) ->
              json.source = source
              session.reset(json)
            , (error) ->
              notifier.error "Import error", error
        else
          session.reset()
      ]
    controller: [ "$scope", "$location", "session", ($scope, $location, session) ->
      $scope.$watch ( -> session.getEditPath()), (path) ->
        $location.path("/#{path}")
    ]
]

module.run ["$rootScope", ($rootScope) ->
  $rootScope[k] = v for k, v of window._plunker
]