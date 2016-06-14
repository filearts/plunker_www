#= require angular-1.0.js
#= require ui-bootstrap/ui-bootstrap-tpls-0.3.0
#= require angularytics/dist/angularytics

#= require ./../services/importer
#= require ./../services/session
#= require ./../services/notifier
#= require ./../services/panes

#= require ./../directives/userpanel
#= require ./../directives/toolbar
#= require ./../directives/overlay
#= require ./../directives/layout

module = angular.module "plunker.editorPage", [
  "plunker.userpanel"
  "plunker.toolbar"
  "plunker.overlay"
  "plunker.layout"
  "plunker.importer"
  "plunker.session"
  "plunker.notifier"
  "plunker.panes"
  
  "ui.bootstrap"
  
  "angularytics"
]


module.config ["$locationProvider", ($locationProvider) ->
  $locationProvider.html5Mode(true).hashPrefix("!")
]

module.config ["$tooltipProvider", ($tooltipProvider) ->
  $tooltipProvider.options
    appendToBody: true
]

module.config ["$routeProvider", ($routeProvider) ->
  $routeProvider.when "/:source",
    template: "<div></div>"
    reloadOnSearch: false
    resolve:
      dirtyCheck: ["$q", "notifier", "session", ($q, notifier, session) ->
        dfd = $q.defer()
        
        if session.isDirty() and not session.skipDirtyCheck then notifier.confirm "You have unsaved changes. This action will reset your plunk. Are you sure you would like to proceed?",
          confirm: -> dfd.resolve()
          deny: -> dfd.reject()
        else dfd.resolve()
        
        delete session.skipDirtyCheck
        
        dfd.promise
      ]
      source: ["$route", "importer", "session", "notifier", ($route, importer, session, notifier) ->
        if source = $route.current.params.source
          unless source is session.getEditPath()
            importer.import(source).then (json) ->
              if _plunker.bootstrap
                json.description = _plunker.bootstrap.description if _plunker.bootstrap.description
                json.tags = _plunker.bootstrap.tags if _plunker.bootstrap.tags
                json.files = _plunker.bootstrap.files if _plunker.bootstrap.files
              
              json.source = source
              json
            , (error) ->
              notifier.error "Import error", error
        else _plunker.bootstrap or files:
          "index.html":
            filename: "index.html"
            snippet: """
              <!DOCTYPE html>
              <html>
              
                <head>
                  <link rel="stylesheet" href="style.css">
                  <script src="script.js"></script>
                </head>
              
                <body>
                  ${1:<h1>Hello Plunker!</h1>}
                </body>
              
              </html>
            """
          "script.js":
            filename: "script.js"
            content: "// Code goes here\n\n"
          "style.css":
            filename: "style.css"
            content: "/* Styles go here */\n\n"
          "README.md":
            filename: "README.md"
            content: ""
      ]
    controller: [ "$rootScope", "$scope", "$location", "$browser", "$timeout", "$route", "session", "source", "notifier", "panes", ($rootScope, $scope, $location, $browser, $timeout, $route, session, source, notifier, panes) ->
      session.reset(source, { open: $location.search().open }) if source?

      unless panes.active
        unless session.plunk?.id
          panes.open(pane) if pane = panes.findById("catalogue")
        else
          panes.open(pane) if pane = panes.findById("info")

      $scope.$watch ( -> session.getEditPath()), (path) ->
        $location.path("/#{path}").replace()
        
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

module.config ["$tooltipProvider", ($tooltipProvider) ->
  $tooltipProvider.options(appendToBody: true)
]



module.run ["$rootScope", ($rootScope) ->
  $rootScope[k] = v for k, v of window._plunker
]

module.config ["AngularyticsProvider", (AngularyticsProvider) ->
  AngularyticsProvider.setEventHandlers ["Console", "GoogleUniversal"]
]

module.run ["Angularytics", (Angularytics) ->
  Angularytics.init()
]