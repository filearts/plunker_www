#= require ../../vendor/angular

#= require ../services/importer
#= require ../services/session

#= require ../directives/layout

module = angular.module("plunker.editorPage", ["plunker.layout", "plunker.importer", "plunker.session"])


module.config ["$locationProvider", ($locationProvider) ->
  $locationProvider.html5Mode(true)
]

module.config ["$routeProvider", ($routeProvider) ->
  $routeProvider.when "/:source",
    template: "<div>Hello</div>"
    resolve: ["$route", "importer", "session", ($route, importer, session) ->
      console.log "Routed", $route.current.params
      if source = $route.current.params.source
        importer.import(source).then (json) ->
          console.log "Session.reset: ", json
          session.reset(json)
        , (error) ->
          console.log "Import error:", arguments...
      else
        session.reset()
    ]
    controller: [ () ->
      
    ]
]

module.run ["$rootScope", ($rootScope) ->
]