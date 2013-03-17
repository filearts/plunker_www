#= require ./../../vendor/ui-bootstrap/ui-bootstrap-tpls-0.2.0


#= require ./../services/users
#= require ./../services/menu

#= require ./../directives/gallery
#= require ./../directives/pager


module = angular.module "plunker.members", [
  "plunker.users"
  "plunker.gallery"
  "plunker.pager"
  "plunker.menu"
  "ui.bootstrap"
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

module.run ["$templateCache", ($templateCache) ->
  $templateCache.put "template/tabs/tabs.html", """
    <div class="tabbable">
      <ul class="nav nav-tabs">
        <li ng-repeat="pane in panes" ng-class="{active:pane.selected}">
          <a ng-click="select(pane)">{{pane.heading}}</a>
        </li>
      </ul>
      <div class="tab-content" ng-transclude></div>
    </div>
  """
]

createProfileHandler = (pane = "plunks") ->
  reloadOnSearch: true
  template: """
    <div class="container">
      <div class="row">
        <div class="span3">
          <div class="thumbnail">
            <img ng-src="http://www.gravatar.com/avatar/{{user.gravatar_id}}?s=260" />
          </div>
          <h3>{{user.login}}</h3>
          <hr />
          <p>
            <i class="icon-github"></i> Github profile:
            <a class="github-link" ng-href="https://github.com/{{user.login}}" ng-bind="user.login"></a>
          </p>
          <p>
            <i class="icon-calendar"></i> Member since:
            <span class="join-date" ng-bind-template="{{user.created_at | date}}"></span>
          </p>
        </div>
        <div class="span9" ng-switch on="activePane">
          <ul class="nav nav-tabs">
            <li ng-repeat="pane in panes" ng-class="{active:pane.name==activePane}">
              <a ng-href="{{pane.url}}">{{pane.heading}}</a>
            </li>
          </ul>
          <div ng-switch-when="plunks">
            <plunker-gallery plunks="plunks"></plunker-gallery>

            <div class="row">
              <plunker-pager class="pull-right" collection="plunks"></plunker-pager>
            </div>
          </div>
          <div ng-switch-when="favorites">
            <plunker-gallery plunks="favorites"></plunker-gallery>

            <div class="row">
              <plunker-pager class="pull-right" collection="favorites"></plunker-pager>
            </div>
          </div>
        </div>
      </div>
    </div>
  """
  resolve:
    user: ["$route", "users", ($route, users) ->
      user = users.findOrCreate(login: $route.current.params.login)
      unless user.$$refreshed_at then user.refresh() else user
    ]
    
  controller: ["$rootScope", "$scope", "$location", "visitor", "user", "menu", ($rootScope, $scope, $location, visitor, user, menu) ->
    $rootScope.page_title = user.login
    
    $scope.user = user
    $scope.visitor = visitor
    $scope.panes = []
    $scope.panes.push
      name: "plunks"
      heading: "Plunks"
      url: "/users/#{user.login}/plunks"
    $scope.panes.push
      name: "favorites"
      heading: "Favorites"
      url: "/users/#{user.login}/favorites"
    $scope.activePane = pane
    
    $scope.$watch "user.id", (id) ->
      if id
        $scope.user.created_at = new Date(parseInt(id.toString().substring(0, 8), 16) * 1000)
    
    $scope.plunks = user.getPlunks(params: $location.search())
    
    $scope.favorites = user.getFavorites(params: $location.search())
    
    menu.activate "users"
  ]


module.config ["$routeProvider", ($routeProvider) ->
  plunksHandler = createProfileHandler("plunks")
  favoritesHandler = createProfileHandler("favorites")
  
  $routeProvider.when "/users/:login", plunksHandler
  $routeProvider.when "/users/:login/plunks", plunksHandler
  $routeProvider.when "/users/:login/plunks/:filter", plunksHandler
  $routeProvider.when "/users/:login/favorites", favoritesHandler
  $routeProvider.when "/users/:login/favorites/:filter", favoritesHandler

]

module.run ["menu", (menu) ->
  menu.addItem "users",
    title: "Explore users"
    href: "/users"
    'class': "icon-group"
    text: "Users"
]
