require "angular-1.2"
require "ui-router/ui-router"
#require "marked.js"
require "angularytics/dist/angularytics"

require "../services/modes.coffee"
require "../directives/markdown.coffee"

module = angular.module "plunker.embed", [
  "ui.router"
  
  "plunker.modes"
  "plunker.markdown"
  
  "angularytics"
]

module.config ["$stateProvider", "$urlRouterProvider", "$locationProvider", ($stateProvider, $urlRouterProvider, $locationProvider) ->
  $locationProvider.html5Mode(true).hashPrefix('!')
  
  $urlRouterProvider.otherwise "/"
]

module.controller "EmbedController", ["$rootScope", "$state", ($rootScope, $state) ->
  $rootScope.$state = $state
  $rootScope.showfiles = false
  $rootScope.toggleFiles = (show = !$rootScope.showfiles) -> $rootScope.showfiles = show
]


module.config ["$stateProvider", "$urlRouterProvider", ($stateProvider, $urlRouterProvider) ->
  $stateProvider.state "embed",
    url: "/:plunkId"
    template: """<div ui-view></div>"""
    controller: ["$scope", "$state", ($scope, $state) ->
      $state.go "embed.preview" if $state.is("embed")
    ]
    
  $stateProvider.state "embed.preview",
    url: "/preview"
    template: """
      <div class="preview">
        <iframe ng-src="{{previewUrl}}" src="about:blank" width="100%" height="100%" frameborder="0"></iframe>
      </div>
    """
    onEnter: ["$rootScope", ($rootScope) ->
      $rootScope.toggleFiles(false)
    ]
    controller: ["$scope", "$sce", ($scope, $sce) ->
      $scope.previewUrl = $sce.trustAsResourceUrl(plunk.raw_url)
    ]
    
  $stateProvider.state "embed.file",
    url: "/:filename"
    template: """
      <span class="filename" ng-bind="filename"></span>
      <pre ng-bind="source" syntax-highlight="{{filename}}">
      </pre>
    """
    onEnter: ["$rootScope", ($rootScope) ->
      $rootScope.toggleFiles(false)
    ]
    controller: ["$scope", "$sce", "$state", "$stateParams", "sourceCache", ($scope, $sce, $state, $stateParams, sourceCache) ->
      return $state.go("embed.preview") unless $stateParams.filename
                 
      $scope.filename = $stateParams.filename
      $scope.source = 
        if file = window.plunk.files[$stateParams.filename] then file.content or "*** EMPTY FILE ***"
        else "*** NO SUCH FILE ***"
    ]
]

module.run ["$rootScope", "$state", ($rootScope, $state) ->
  $rootScope.$on "$stateChangeStart", (e, toState, toParams, fromState, fromParams) ->
    #console.log "$stateChangeStart", toState.name, "<--", fromState.name
  $rootScope.$on "$stateChangeError", (e, toState, toParams, fromState, fromParams, err) ->
    #console.log "$stateChangeError", toState.name, "-/-", fromState.name
    #console.error err
  $rootScope.$on "$stateChangeSuccess", (e, toState, toParams, fromState, fromParams) ->
    #console.log "$stateChangeSuccess", toState.name, "<==", fromState.name, toParams

]

module.factory "sourceCache", ["$cacheFactory", ($cacheFactory) ->
  $cacheFactory("sourceCode")
]

module.directive "file", ["sourceCache", (sourceCache) ->
  restrict: "A"
  scope:
    filename: "@file"
  link: ($scope, $element, $attrs) ->

    console.log "sourceCache", $scope.filename, $element[0].innerHtml
                          
    sourceCache.put $scope.filename, $element[0].innerHtml
]

module.directive "syntaxHighlight", ["modes", (modes) ->
  staticHighlight = ace.require "ace/ext/static_highlight"
  
  restrict: "A"
  scope:
    filename: "@syntaxHighlight"
  link: ($scope, $element, $attrs) ->
                                     
    $scope.$watch "filename", (filename) ->
      opts =
        mode: modes.findByFilename(filename).source
        showGutter: true
        firstLineNumber: 1
      staticHighlight.highlight $element[0], opts
]