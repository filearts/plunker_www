require "../../vendor/angular/angular"
require "../../vendor/angular/angular-cookies"
require "../../vendor/angular-ui/ui-bootstrap"
require "../../vendor/angular-ui/ui-router"


require "../services/session.coffee"
require "../services/notifier.coffee"
require "../services/disabler.coffee"
require "../services/basePlunk.coffee"
require "../services/layout.coffee"
require "../services/updater.coffee"
require "../services/collab.coffee"
require "../services/api.coffee"
require "../services/dirty.coffee"
require "../services/multipane.coffee"
require "../services/splitter.coffee"
require "../services/project.coffee"
require "../services/workspace.coffee"

require "../directives/borderLayout.coffee"
require "../directives/aceEditor.coffee"
require "../directives/previewer.coffee"
require "../directives/toolbar.coffee"
require "../directives/taglist.coffee"
require "../directives/stopPropagation.coffee"

require "../panes/config.coffee"


module = angular.module "plunker.app.editor", [
  "ui.bootstrap"
  "ui.router"
  
  "fa.borderLayout"
  
  "plunker.service.session"
  "plunker.service.notifier"
  "plunker.service.disabler"
  "plunker.service.basePlunk"
  "plunker.service.layout"
  "plunker.service.updater"
  "plunker.service.collab"
  "plunker.service.api"
  "plunker.service.dirty"
  "plunker.service.multipane"
  "plunker.service.splitter"
  "plunker.service.project"
  "plunker.service.workspace"
  
  "plunker.directive.aceEditor"
  "plunker.directive.previewer"
  "plunker.directive.toolbar"
  "plunker.directive.taglist"
  "plunker.directive.stopPropagation"

  "plunker.pane.config"
]

module.config ["$stateProvider", "$urlRouterProvider", "$locationProvider", ($stateProvider, $urlRouterProvider, $locationProvider) ->
  $locationProvider.html5Mode(true).hashPrefix('!')
  
  $urlRouterProvider.when "/edit", "/edit/"
  
  $urlRouterProvider.otherwise("/")
]

module.config ["$stateProvider", "$urlRouterProvider", ($stateProvider, $urlRouterProvider) ->
  $stateProvider.state "home",
    url: "/"
    template: """
      <div>
        <a ui-sref="editor.reset">Open the editor</a>
        <ul>
          <li ng-repeat="plunk in plunks">
            <a ui-sref="editor.plunk({plunkId: plunk.id})" ng-bind="plunk.description"></a>
          </li>
        </ul>
      </div>
    """
    controller: ["$scope", "api", ($scope, api) ->
      $scope.plunks = []
      
      api.all("plunks").allUrl("plunks", "trending").getList().then (plunks) ->
        angular.copy plunks, $scope.plunks
    ]

  $stateProvider.state "editor",
    url: "/edit"
    abstract: true
    views:
      "sidebar@editor":
        templateUrl: "/partials/panes/sidebar.html"
        controller: ["$scope", "project", "workspace", ($scope, project, workspace) ->
          $scope.project = project
          $scope.workspace = workspace
        ]
      "":
        templateUrl: "/partials/editor.html"
        resolve:
          client: ["session", (session) -> session.createClient("editor") ]
        onEnter: ["layout", (layout) ->
          layout.current.templates.closed = true
        ]
        controller: ["$scope", "basePlunk", "dirty", "api", "layout", "splitter", ($scope, basePlunk, dirty, api, layout, splitter) ->
          $scope.splitter = splitter
          $scope.templates = []
          $scope.templateSearch = taglist: []
    
          $scope.reset = ->
            api.all("templates").getList().then (templates) ->
              angular.copy templates, $scope.templates
              
            $scope.templateSearch = taglist: []
          
          $scope.search = (taglist) ->
            api.all("templates").getList(taglist: taglist.join(",")).then (templates) ->
              angular.copy templates, $scope.templates
          
          $scope.reset()
        
          dirty.markClean()
        ]

  $stateProvider.state "editor.reset",
    url: "/"
    template: ""
    controller: ["$state", ($state) ->
      $state.go "editor.new"
    ]
      
  $stateProvider.state "editor.new",
    url: "/new"
    template: ""
    onEnter: ["layout", (layout) ->
      layout.current.templates.closed = false
    ]
    onExit: ["layout", (layout) ->
      layout.current.templates.closed = true
    ]
    controller: ["$scope", "session", "basePlunk", "notifier", "layout", "updater", "disabler", "dirty", ($scope, session, basePlunk, notifier, layout, updater, disabler, dirty) ->
      client = session.createClient("editor.new")
      
      disabler.enqueue "editor", updater.update(basePlunk).then (json) ->
        client.reset json
        client.cursorSetIndex (0 <= idx = client.getFileIndex("index.html")) and idx or 0
        
        dirty.markClean()
      
        notifier.success "Plunk reset"
    ]


  $stateProvider.state "editor.stream",
    url: "/stream:{streamId:[a-z0-9]+}"
    template: ""
    controller: ["$stateParams", "$q", "$http", "$scope", "$state", "$timeout", "collab", "notifier", "disabler", "layout", "updater", ($stateParams, $q, $http, $scope, $state, $timeout, collab, notifier, disabler, layout, updater) ->
      disabler.enqueue "editor", collab.connect($stateParams.streamId).then (json) ->
        notifier.success "Connected to stream: #{$stateParams.streamId}"
      , ->
        notifier.error "Failed to connect to stream"
      
    ]

        
  $stateProvider.state "editor.gist",
    url: "/gist:{gistId:[0-9]+|[0-9a-z]{20}}"
    template: ""
    controller: ["$stateParams", "$q", "$http", "$scope", "$state", "$timeout", "client", "notifier", "disabler", "layout", "updater", "dirty", ($stateParams, $q, $http, $scope, $state, $timeout, client, notifier, disabler, layout, updater, dirty) ->
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
        
        updater.update(json)
      , (error) ->
        console.log "[ERR] Pulling gist", error
        
        $q.reject("Unable to load gist")
        
      parser.then (json) ->
        layout.current.templates.closed = true
        client.reset json
        client.cursorSetIndex (0 <= idx = client.getFileIndex("index.html")) and idx or 0
        
        dirty.markClean()

        notifier.success "Imported gist #{$stateParams.gistId}"
      , (errorText) ->
        $state.go "editor.reset"
        notifier.error errorText
    ]

        
  $stateProvider.state "editor.plunk",
    url: "/{plunkId:[a-zA-Z0-9]+}"
    template: ""
    resolve:
      plunk: ["$stateParams", "disabler", "project", "notifier", ($stateParams, disabler, project, notifier) ->
        disabler.enqueue "editor", project.load($stateParams.plunkId).then ->
          project.plunk
        , ->
          notifier.error "Failed to load plunk"
      ]
    controller: ["$stateParams", "$scope", "$state", "client", "notifier", "disabler", "layout", "updater", "plunk", "dirty", ($stateParams, $scope, $state, client, notifier, disabler, layout, updater, plunk, dirty) ->
      json =
        description: plunk.description
        tags: plunk.tags
        files: (file for filename, file of plunk.files)
      
      client.reset json
      client.cursorSetIndex (0 <= idx = client.getFileIndex("index.html")) and idx or 0
      
      dirty.markClean()
      
      notifier.success "Opened plunk: #{$stateParams.plunkId}"
    ]
]

module.run ["$rootScope", "$state", ($rootScope, $state) ->
  $rootScope.$on "$stateChangeSuccess", (e) ->
]

module.controller "SidebarController", ["$scope", "session", "splitter", ($scope, session, splitter) ->
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
  
  $scope.moveTo = (filename, $event) ->
    if $event.shiftKey
      splitter.split()
      splitter.focus(splitter.splits - 1)
      
    client.cursorSetFile(filename)
]


module.controller "LayoutController", ["$scope", "layout", "multipane", ($scope, layout, multipane) ->
  $scope.layout = layout

  $scope.toggleTemplatePane = ->
    layout.current.templates.closed = !layout.current.templates.closed
    
  $scope.togglePreviewPane = ->
    $scope.showPreviewPane = !$scope.showPreviewPane
  
  $scope.multipane = multipane
]