#= require ./../../vendor/ui-bootstrap/ui-bootstrap-tpls-0.3.0

#= require ./../services/visitor


module = angular.module "plunker.userpanel", [
  "plunker.visitor"
  "ui.bootstrap"
] 

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
      <button ng-switch-when="false" ng-disabled="visitor.isLoading()" class="user-login btn btn-primary" tooltip="Sign in to get full access" tooltip-placement="bottom" ng-click="visitor.login()">
        <i class="icon-github" />
        <span class="text shrink">Sign in with Github</span>
      </button>
      <iframe class="gittip" src="https://www.gittip.com/ggoodman/widget.html" width="48pt" height="22pt"></iframe>
    </div>
  """
  controller: ["$scope", "visitor", ($scope, visitor) ->
    $scope.visitor = visitor
  ]
]