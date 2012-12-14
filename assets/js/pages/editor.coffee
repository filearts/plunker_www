#= require ../../vendor/angular.js
#= require ../../vendor/bootstrap/js/bootstrap-button.js

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
    reloadOnSearch: false
    resolve:
      dirtyCheck: ["$q", "notifier", "session", ($q, notifier, session) ->
        dfd = $q.defer()
        
        if session.isDirty() then notifier.confirm "You have unsaved changes. This action will reset your plunk. Are you sure you would like to proceed?",
          confirm: -> dfd.resolve()
          deny: -> dfd.reject()
        else dfd.resolve()
        
        dfd.promise
      ]
      source: ["$route", "importer", "session", "notifier", ($route, importer, session, notifier) ->
        if source = $route.current.params.source
          unless source and source is session.getEditPath()
            importer.import(source).then (json) ->
              json.source = source
              json
            , (error) ->
              notifier.error "Import error", error
        else {}
      ]
    controller: [ "$rootScope", "$scope", "$location", "$browser", "$timeout", "$route", "session", "source", ($rootScope, $scope, $location, $browser, $timeout, $route, session, source) ->
      session.reset(source)
      
      $scope.$watch ( -> session.getEditPath()), (path) ->
        $location.path("/#{path}")
        
      lastValidUrl = $location.absUrl()
      lastValidRoute = $route.current

      $rootScope.$on "$routeChangeError", (curr, prev) ->
        $route.current = lastValidRoute
        $location.$$parse lastValidUrl
        $browser.url lastValidUrl, true
        
        window.history.back()
        
      $rootScope.$on "$routeChangeSuccess", (curr, prev) ->
        lastValidUrl = $location.absUrl()
        lastValidRoute = $route.current
    ]
]

module.run ["$rootScope", ($rootScope) ->
  $rootScope[k] = v for k, v of window._plunker
]