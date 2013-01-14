#= require ../services/users
#= require ../services/menu

#= require ../directives/timeago


module = angular.module "plunker.profile", [
  "plunker.users"
  "plunker.timeago"
  "plunker.menu"
]

module.config ["$routeProvider", ($routeProvider) ->
  $routeProvider.when "/users/:login",
    template: """
      <div class="container">
        <div class="page-header">
            <h1>{{user.login}} <small>User since <abbr timeago="user.created_at" title="{{user.updated_at}}" ng-bind="user.updated_at | date:'medium'"></abbr></small></h1>
        </div>
        <div class="row">
          <div class="span12">
          </div>
        </div>
      </div>
    """
    resolve:
      user: ["$route", "users", ($route, users) ->
        user = users.findOrCreate(login: $route.current.params.login)
        user.refresh() unless user.$$refreshed_at
      ]
      
    controller: ["$scope", "visitor", "user", "menu", ($scope, visitor, user, menu) ->
      $scope.user = user
      $scope.visitor = visitor
      
      $scope.$watch "user.id", (id) ->
        if id
          $scope.user.created_at = new Date(parseInt(id.toString().substring(0, 8), 16) * 1000)
          
      
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
