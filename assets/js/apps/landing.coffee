#= require ./../../vendor/angular

#= require ./../controllers/explore
#= require ./../controllers/members
#= require ./../controllers/tags
#= require ./../controllers/editor
#= require ./../controllers/packages
#= require ./../controllers/preview
#= require ./../controllers/notfound

#= require ./../services/menu
#= require ./../services/plunks
#= require ./../services/users

#= require ./../directives/userpanel


module = angular.module "plunker.landing", [
  "plunker.explore"
  "plunker.tags"
  "plunker.members"
  "plunker.editorPage"
  "plunker.packages"
  "plunker.preview"
  "plunker.notfound"
  "plunker.menu"
  "plunker.userpanel"
  "plunker.plunks"
]


module.config ["$locationProvider", ($locationProvider) ->
  $locationProvider.html5Mode(true)
]

module.run ["$rootScope", "$location", "$window", "menu", ($rootScope, $location, $window, menu) ->
  $rootScope[k] = v for k, v of _plunker
  $rootScope.menu = menu
]

module.run ["plunks", (plunks) ->
  
  if bootstrap = _plunker.bootstrap?.plunks
    for json in bootstrap
      plunks.findOrCreate(json).$$updated_at = Date.now()
]

module.run ["$rootElement", ($rootElement) ->
  $("body").on "click", (event) ->
    if event.ctrlKey || event.metaKey || event.which == 2 then return
  
    elm = angular.element(event.target)
  
    while angular.lowercase(elm[0].nodeName) != 'a'
      if elm[0] == $rootElement[0] || !(elm = elm.parent())[0] then return
    
    if (href = elm.prop("href")) and href.match(/\/edit\//)
      event.stopPropagation()
      window.location = href
]

