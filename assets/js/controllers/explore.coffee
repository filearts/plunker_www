#= require ../services/menu
#= require ../services/plunks
#= require ../services/url

#= require ../directives/gallery
#= require ../directives/overlay
#= require ../directives/pager

module = angular.module "plunker.explore", [
  "plunker.gallery"
  "plunker.pager"
  "plunker.overlay"
  "plunker.menu"
  "plunker.plunks"
  "plunker.url"
]

filters =
  trending:
    href: "/plunks/trending"
    text: "Trending"
    order: "c"
  popular:
    href: "/plunks/popular"
    text: "Popular"
    order: "b"
  recent:
    href: "/plunks/recent"
    text: "Recent"
    order: "a"

resolvers =
  trending: [ "url", "plunks", (url, plunks) ->
    plunks.query(url: "#{url.api}/plunks/trending").$$refreshing
  ]
  popular: [ "url", "plunks", (url, plunks) ->
    plunks.query(url: "#{url.api}/plunks/popular").$$refreshing
  ]
  recent: [ "url", "plunks", (url, plunks) ->
    plunks.query(url: "#{url.api}/plunks").$$refreshing
  ]

generateRouteHandler = (filter) ->
  templateUrl: "partials/explore.html"
  resolve:
    filtered: resolvers[filter]
  controller: ["$scope", "menu", "filtered", ($scope, menu, filtered) ->
    $scope.plunks = filtered
    $scope.filters = filters
    $scope.activeFilter = filters[filter]
    
    menu.activate "plunks"
  ]

module.config ["$routeProvider", ($routeProvider) ->
  $routeProvider.when "/", generateRouteHandler("trending")
  $routeProvider.when "/plunks/#{view}", generateRouteHandler(view) for view in ["trending", "popular", "recent"]
]

module.run ["menu", (menu) ->
  menu.addItem "plunks",
    title: "Explore plunks"
    href: "/"
    'class': "icon-th"
    text: "Plunks"
]
