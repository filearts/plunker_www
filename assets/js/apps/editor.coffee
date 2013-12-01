fs = require("fs")
_ = require("lodash")

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
require "../services/importer.coffee"
require "../services/collab.coffee"
require "../services/api.coffee"
require "../services/dirty.coffee"
require "../services/oauth.coffee"
require "../services/multipane.coffee"
require "../services/project.coffee"
require "../services/workspace.coffee"
require "../services/keybindings.coffee"

require "../directives/borderLayout.coffee"
require "../directives/aceEditor.coffee"
require "../directives/previewer.coffee"
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
  "plunker.service.importer"
  "plunker.service.collab"
  "plunker.service.api"
  "plunker.service.dirty"
  "plunker.service.multipane"
  "plunker.service.project"
  "plunker.service.workspace"
  "plunker.service.oauth"
  "plunker.service.keybindings"
  
  "plunker.directive.aceEditor"
  "plunker.directive.previewer"
  "plunker.directive.taglist"
  "plunker.directive.stopPropagation"

  "plunker.pane.config"
]

module.run ["keybindings", (keybindings) ->
  keybindings.addCommand
    name: "Save"
    bindKey:
      win: "Ctrl-S"
      mac: "Command-S"
    exec: ["project", (project) ->
      console.log "Save"
    ]
  keybindings.addCommand
    name: "Reset"
    bindKey:
      win: "Ctrl-R"
      mac: "Command-R"
    exec: ["$state", ($state) ->
      $state.go "editor.reset"
    ]
  keybindings.addCommand
    name: "Toggle Preview"
    bindKey:
      win: "Ctrl-Shift-Enter"
      mac: "Command-Shift-Enter"
    exec: ["layout", (layout) ->
      console.log "Toggling preview"
      #layout.current.preview.closed = !layout.current.preview.closed
      layout.toggle "preview"
    ]
  keybindings.addCommand
    name: "Next"
    bindKey:
      win: "Ctrl-Down"
      mac: "Command-Down"
    exec: ["workspace", (workspace) ->
      workspace.openNext()
    ]
  keybindings.addCommand
    name: "Prev"
    bindKey:
      win: "Ctrl-Up"
      mac: "Command-Up"
    exec: ["workspace", (workspace) ->
      workspace.openPrev()
    ]
]

module.config ["$stateProvider", "$urlRouterProvider", ($stateProvider, $urlRouterProvider) ->
  $urlRouterProvider.when "/edit/gist:{gistId:[0-9]+|[0-9a-z]{20}}", ["$match", ($match) ->
    return "/edit/?import=gist:#{$match.gistId}"
  ]

  $urlRouterProvider.when "/edit/tpl:{gistId:[0-9]+|[0-9a-z]{20}}", ["$match", ($match) ->
    return "/edit/?import=template:#{$match.gistId}"
  ]

  $stateProvider.state "editor",
    abstract: true
    url: "/edit"
    views:
      "templates@editor":
        templateUrl: "/partials/panes/templates.html"
        controller: ["$scope", "$rootElement", "api", "keybindings", ($scope, $rootElement, api, keybindings) ->
          $scope.templates = []
          $scope.templateSearch = taglist: ""
                     
          keybindings.attachTo $rootElement[0]
                     
          split = (input) -> _(input.split(/[,\s]+/)).map((s)->s.trim()).filter((s)->!!s).value()
                     
          $scope.addTag = (tagName) ->
            console.log "Before add", $scope.templateSearch.taglist, typeof $scope.templateSearch.taglist, !!$scope.templateSearch.taglist
            $scope.templateSearch.taglist += ", " if $scope.templateSearch.taglist
            $scope.templateSearch.taglist += tagName
            $scope.search $scope.templateSearch.taglist
    
          $scope.reset = ->
            api.all("templates").getList().then (templates) ->
              angular.copy templates, $scope.templates
              
            $scope.templateSearch = taglist: ""
          
          $scope.search = (taglist) ->
            console.log "Split", taglist, split(taglist)
            api.all("templates").getList(taglist: split(taglist).join(",")).then (templates) ->
              angular.copy templates, $scope.templates
          
          $scope.reset()
        ]        
      "toolbar@editor":
        templateUrl: "/partials/panes/toolbar.html"
        controller:  [ "$scope", "workspace", "project", "visitor", "oauth", "layout", ($scope, workspace, project, visitor, oauth, layout) ->
          $scope.workspace = workspace
          $scope.project = project
          $scope.visitor = visitor
          $scope.layout = layout

          $scope.login = ->
            $scope.disableLogin = true
            login = oauth.authenticate().then (authInfo) ->
              visitor.login(authInfo)
            
            login.finally ->
              $scope.disableLogin = false
          
          $scope.logout = ->
            $scope.disableLogout = true
            logout = visitor.logout()
            logout.finally ->
              $scope.disableLogout = false
        ]
      "sidebar@editor":
        templateUrl: "/partials/panes/sidebar.html"
        controller: ["$scope", "project", "workspace", "notifier", ($scope, project, workspace, notifier) ->
          $scope.project = project
          $scope.workspace = workspace

          $scope.fileCreate = ->
            notifier.prompt("Filename?").then (filename) ->
              if filename
                project.fileCreate(filename)
                workspace.open(filename)
          
          $scope.fileRename = (filename) ->
            if project.hasFile(filename) then notifier.prompt("Rename #{filename} to:").then (newFilename) ->
              if newFilename
                 project.fileRename(filename, newFilename)
          
          $scope.fileRemove = (filename) ->
            if project.getFileCount() <= 1 then notifier.warn("Unable to delete all files")
            else if project.hasFile(filename) then notifier.confirm("Are you sure you would like to delete #{filename}?").then (answer) ->
              if answer then project.fileRemove(filename)
        ]
      "paneselector@editor":
        templateUrl: "/partials/panes/paneselector.html"
        controller: ["$scope", "multipane", ($scope, multipane) ->
          $scope.multipane = multipane
        ]
      "":
        templateUrl: "/partials/editor.html"
        onEnter: ["layout", (layout) ->
          layout.current.templates.closed = true
        ]
        controller: ["$scope", "workspace", "project", "layout", ($scope, workspace, project, layout) ->
          $scope.workspace = workspace
          $scope.project = project
          $scope.layout = layout
        ]

  # Reset state exists to allow a state change to be triggered even when already in editor.new
  $stateProvider.state "editor.reset",
    template: ""
    controller: ["$state", "project", "dirty", "notifier", "updater", "basePlunk", "disabler", ($state, project, dirty, notifier, updater, basePlunk, disabler) ->
      project.reset basePlunk
      $state.transitionTo "editor.new"
    ]

  # This state exists to allow the updater to fail, but the editor to still function
  # It is an intermediate between 'editor.reset' and 'editor.edit'
  $stateProvider.state "editor.new",
    url: "/?import"
    template: ""
    onEnter: ["layout", (layout) ->
      layout.current.templates.closed = false
    ]
    controller: ["$q", "$stateParams", "disabler", "workspace", "project", "basePlunk", "notifier", "updater", "importer", "dirty", ($q, $stateParams, disabler, workspace, project, basePlunk, notifier, updater, importer, dirty) ->
      reset = $q.when do ->
        if $stateParams.import then importer.import($stateParams.import)
        else basePlunk
          
      reset = reset.then (json) -> updater.update(json)
       
      reset.then (json) ->
        project.reset(json)
        
        workspace.paneClose("templates") if $stateParams.import

        notifier.success "Plunk reset"
      , (e) ->
        notifier.warn "Unable to update dependencies"
                 
      reset.finally ->
        dirty.markClean()
        workspace.open "index.html" if project.hasFile("index.html")
      
      disabler.enqueue "editor", reset
    ]

  $stateProvider.state "editor.plunk",
    url: "/{plunkId:[a-zA-Z0-9]+}"
    template: ""
    onEnter: ["workspace", (workspace) ->
      workspace.paneClose "templates"
    ]
    controller: ["$stateParams", "$state", "disabler", "workspace", "project", "basePlunk", "notifier", "updater", "layout", "dirty", ($stateParams, $state, disabler, workspace, project, basePlunk, notifier, updater, layout, dirty) ->
      disabler.enqueue "editor", open = project.openPlunk($stateParams.plunkId).then ->
        notifier.success "Opened plunk: #{$stateParams.plunkId}"

        dirty.markClean()
        workspace.open "index.html" if project.hasFile("index.html")
      , (e) ->
        notifier.error "Failed to load plunk"
        
        $state.transitionTo "editor.reset"
    ]
        
  $stateProvider.state "editor.gist",
    url: "/gist:{gistId:[0-9]+|[0-9a-z]{20}}"
    template: ""
    controller: ["$stateParams", "$q", "$http", "$scope", "$state", "$timeout", "project", "notifier", "disabler", "layout", "updater", "dirty", ($stateParams, $q, $http, $scope, $state, $timeout, project, notifier, disabler, layout, updater, dirty) ->
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
        
        updater.update(json).catch (err) ->
          notifier.warn "Unable to update dependencies"
          
          $q.resolve(json)
        
      parser.then (json) ->
        project.reset json

        notifier.success "Imported gist #{$stateParams.gistId}"
        
        $state.go "editor.edit"
      , (errorText) ->
        notifier.error "Unable to import gist #{$stateParams.gistId}"
        
        $state.go "editor.reset"
    ]

]

module.run ["$rootScope", "$state", ($rootScope, $state) ->
  $rootScope.$on "$stateChangeStart", (e, toState, toParams, fromState, fromParams) ->
    console.log "$stateChangeStart", toState.name, "<--", fromState.name
  $rootScope.$on "$stateChangeError", (e, toState, toParams, fromState, fromParams, err) ->
    console.log "$stateChangeError", toState.name, "-/-", fromState.name
    console.error err
  $rootScope.$on "$stateChangeSuccess", (e, toState, toParams, fromState, fromParams) ->
    console.log "$stateChangeSuccess", toState.name, "<==", fromState.name, toParams
    debugger if toState.name is "editor.edit" and fromState.name is "editor.new"
]