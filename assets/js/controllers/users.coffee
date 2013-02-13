#= require ../services/users
#= require ../services/menu

#= require ../directives/timeago


module = angular.module "plunker.users", [
  "plunker.users"
  "plunker.timeago"
  "plunker.menu"
]

module.config ["$routeProvider", ($routeProvider) ->
  $routeProvider.when "/users",
    template: """
      <h1>TO DO</h1>
    """

    controller: ["$rootScope", "$scope", "menu", ($rootScope, $scope, menu) ->
      $rootScope.page_title = "Users"          
      
      menu.activate "users"
    ]
]

module.run ["menu", (menu) ->
  menu.addItem "users",
    title: "Explore users"
    href: "/users"
    'class': "icon-group"
    text: "Users"
]
