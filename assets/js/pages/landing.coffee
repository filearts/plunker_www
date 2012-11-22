#= require ../../vendor/angular

#= require ../controllers/landing
#= require ../controllers/preview

#= require ../services/menu

#= require ../directives/userpanel


module = angular.module("plunker.landingPage", ["plunker.landing", "plunker.preview", "plunker.menu", "plunker.userpanel"])


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
    
  $rootScope.$on "$routeChangeStart", ->
    if $location.path().match(/^\/edit\//)
      window.location = $location.absUrl()
]