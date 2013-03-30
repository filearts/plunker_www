#= require ./../services/visitor


module = angular.module("plunker.userpanel", ["plunker.visitor"])

module.directive "plnkrPress", ["$parse", ($parse) ->
  (scope, element, attrs) ->
    tapping = false
    fn = $parse(attrs["plnkrPress"])
    
    element.bind 'touchstart', (e) -> tapping = true
    element.bind 'touchmove', (e) -> tapping = false
    element.bind 'touchend', (e) -> if tapping then scope.$apply -> fn(scope, $event: e)
    element.bind 'click', (e) -> scope.$apply -> fn(scope, $event: e)
]

module.directive "plunkerUserpanel", [ ->
  restrict: "E"
  replace: true
  template: """
    <div class="plunker-userpanel pull-right" ng-switch on="visitor.logged_in">
      <div class="btn-group" ng-switch-when="true">
        <button class="user-menu btn dropdown-toggle" data-toggle="dropdown" title="User options">
          <img class="gravatar" src="http://www.gravatar.com/avatar/{{visitor.user.gravatar_id}}?s=20" />
          <span class="text shrink">{{visitor.user.login}}</span>
          <b class="caret" />
        </button>
        <ul class="dropdown-menu">
          <li>
            <a href="/users/{{visitor.user.login}}">My plunks</a>
          </li>
          <li>
            <a href="/users/{{visitor.user.login}}/favorites">Starred plunks</a>
          </li>
          <li class="divider"></li>
          <li>
            <a class="logout" href="javascript:void(0)" plnkr-press="visitor.logout()">Logout</a>
          </li>
        </ul>
      </div>
      <div class="btn-group" ng-switch-when="false">
        <button class="user-login btn dropdown-toggle" data-toggle="dropdown" title="Sign in">
          <i class="icon-user" />
          <span class="text shrink">Sign in</span>
          <span class="caret"></span>
        </button>
        <ul class="dropdown-menu">
          <li>
            <a class="login login-github" data-service="github" href="javascript:void(0)" plnkr-press="visitor.login()">
              <i class="icon-github" />
              Sign in with Github
            </a>
          </li>
        </ul>
      </div>
    </div>
  """
  controller: ["$scope", "visitor", ($scope, visitor) ->
    $scope.visitor = visitor
  ]
]