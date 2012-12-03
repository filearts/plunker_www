#= require ../../vendor/angular.js

#= require ../controllers/explore
#= require ../controllers/preview

#= require ../services/menu

#= require ../directives/userpanel


module = angular.module("plunker.landing", ["plunker.explore", "plunker.preview", "plunker.menu", "plunker.userpanel"])


module.config ["$locationProvider", ($locationProvider) ->
  $locationProvider.html5Mode(true)
]

module.run ["$rootScope", "$location", "$window", "menu", ($rootScope, $location, $window, menu) ->
  $rootScope[k] = v for k, v of _plunker
  $rootScope.menu = menu
  
  menu.addItem "editor",
    title: "Launch the Editor"
    href: "/edit/"
    'class': "icon-edit"
    text: "Editor"
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

