#= require ../../vendor/angular

#= require ../controllers/explore
#= require ../controllers/preview
#= require ../controllers/editor
#= require ../controllers/notfound

#= require ../services/menu

#= require ../directives/userpanel


module = angular.module "plunker.landing", [
  "plunker.explore"
  "plunker.preview"
  "plunker.editorPage"
  "plunker.notfound"
  "plunker.menu"
  "plunker.userpanel"
]


module.config ["$locationProvider", ($locationProvider) ->
  $locationProvider.html5Mode(true)
]

module.run ["$rootScope", "$location", "$window", "menu", ($rootScope, $location, $window, menu) ->
  $rootScope[k] = v for k, v of _plunker
  $rootScope.menu = menu
  
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

