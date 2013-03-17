#= require ./../services/menu

#= require ./../directives/timeago


module = angular.module "plunker.tags", [
  "plunker.timeago"
  "plunker.menu"
]

module.config ["$routeProvider", ($routeProvider) ->
  $routeProvider.when "/tags",
    template: """
      <h1>TO DO</h1>
    """

    controller: ["$rootScope", "$scope", "menu", ($rootScope, $scope, menu) ->
      $rootScope.page_title = "Tags"          
      
      menu.activate "tags"
    ]
]

module.run ["menu", (menu) ->
  menu.addItem "tags",
    title: "Explore tags"
    href: "/tags"
    'class': "icon-tags"
    text: "Tags"
]
