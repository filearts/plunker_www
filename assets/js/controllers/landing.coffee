#= require ../services/menu

#= require ../directives/gallery
#= require ../directives/overlay

module = angular.module("plunker.landing", ["plunker.gallery", "plunker.overlay", "plunker.menu"])


module.config ["$routeProvider", ($routeProvider) ->
  $routeProvider.when "/", do ->
    templateUrl: "partials/explore.html"
    controller: [ "menu", (menu) ->
      menu.activate "plunks"
    ]
]

module.run ["menu", (menu) ->
  menu.addItem "plunks",
    title: "Explore plunks"
    href: "/"
    'class': "icon-th"
    text: "Plunks"
]