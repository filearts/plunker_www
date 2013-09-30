require "../../vendor/angular/angular"
require "../../vendor/angular/angular-cookies"
require "../../vendor/angular-ui/ui-bootstrap"
require "../../vendor/angular-ui/ui-router"


require "../services/session.coffee"
require "../services/notifier.coffee"
require "../services/disabler.coffee"
require "../services/basePlunk.coffee"
require "../services/layout.coffee"

require "../directives/borderLayout.coffee"
require "../directives/codeEditor.coffee"
require "../directives/previewer.coffee"
require "../directives/toolbar.coffee"


module = angular.module "plunker.app.editor", [
  "ui.bootstrap"
  "ui.router"
  
  "fa.borderLayout"
  
  "plunker.service.session"
  "plunker.service.notifier"
  "plunker.service.disabler"
  "plunker.service.basePlunk"
  "plunker.service.layout"
  
  "plunker.directive.codeEditor"
  "plunker.directive.previewer"
  "plunker.directive.toolbar"
]

module.config ["$stateProvider", "$urlRouterProvider", "$locationProvider", ($stateProvider, $urlRouterProvider, $locationProvider) ->
  $locationProvider.html5Mode true
  
  $urlRouterProvider.when "/edit", "/edit/"
  
  $urlRouterProvider.otherwise("/edit/")
]

module.config ["$stateProvider", "$urlRouterProvider", ($stateProvider, $urlRouterProvider) ->
  
  $stateProvider.state "editor",
    url: "/edit"
    template: """
      <div ui-view="body"></div>
    """
    controller: ["$state", "$scope", ($state, $scope) ->
      $scope.showTemplatePane = true
      $scope.showPreviewPane = false
      $state.go "editor.blank" if $state.is("editor")
    ]
    
  $stateProvider.state "editor.blank",
    url: "/"
    views:
      "body": 
        templateUrl: "/partials/editor.html"
        controller: ["$scope", "session", "basePlunk", "notifier", ($scope, session, basePlunk, notifier) ->
          client = session.createClient("edit.blank")
          
          client.reset basePlunk
          client.cursorSetIndex (0 <= idx = client.getFileIndex("index.html")) and idx or 0
          
          notifier.success "Plunk reset"
        ]


        
  $stateProvider.state "editor.gist",
    url: "/gist:{gistId:[0-9]+|[0-9a-z]{20}}"
    views:
      "body": 
        templateUrl: "/partials/editor.html"
        controller: ["$stateParams", "$q", "$http", "$scope", "$state", "$timeout", "session", "notifier", "disabler", ($stateParams, $q, $http, $scope, $state, $timeout, session, notifier, disabler) ->
          
          client = session.createClient("edit.gist")
          
          disabler.enqueue "editor", request = $http.jsonp("https://api.github.com/gists/#{$stateParams.gistId}?callback=JSON_CALLBACK")
          
          parser = request.then (response) ->
            if response.data.meta.status >= 400 then return $q.reject("Gist not found")
            
            gist = response.data.data
            json = 
              'private': true
              files: []
            
            if manifest = gist.files["plunker.json"]
              try
                angular.extend json, angular.fromJson(manifest.content)
              catch e
                notifier.warn "Unable to parse the plunker.json file"
    
            json.description = gist.description or "https://gist.github.com/#{$stateParams.gistId}"
  
            for filename, file of gist.files
              unless filename == "plunker.json"
                json.files.push
                  filename: filename
                  content: file.content 
            
            json
          , (error) ->
            console.log "[ERR] Pulling gist", error
            
            $q.reject("Unable to load gist")
            
          parser.then (json) ->
            $scope.showTemplatePane = false
            client.reset json
            client.cursorSetIndex (0 <= idx = client.getFileIndex("index.html")) and idx or 0
            notifier.success "Imported plunk"
          , (errorText) ->
            $state.go "editor.blank"
            notifier.error errorText
        ]
]

module.controller "SidebarController", ["$scope", "session", ($scope, session) ->
  $scope.session = client = session.createClient("SidebarController")
  
  $scope.addFile = ->
    if filename = prompt("Filename?")
      client.fileCreate(filename)
      client.cursorSetFile(filename)
  
  $scope.renameFile = (old_filename) ->
    if client.hasFile(old_filename) and filename = prompt("Filename?", old_filename)
      client.fileRename(old_filename, filename)    
  
  $scope.removeFile = (filename) ->
    if client.hasFile(filename) and confirm("Are you sure you would like to delete #{filename}?")
      client.fileRemove(filename)
  
  $scope.moveTo = (filename) ->
    client.cursorSetFile(filename)
]


module.controller "LayoutController", ["$scope", "layout", ($scope, layout) ->
  $scope.layout = layout
  $scope.togglePreviewPane = ->
    $scope.showPreviewPane = !$scope.showPreviewPane
]