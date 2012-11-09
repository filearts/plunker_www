module = angular.module "plunker.inlineuser", []

module.directive "plunkerInlineUser", [ "$rootScope", ($rootScope) ->
  restrict: "E"
  scope:
    user: "="
  template: """
    <span class="inline-user" ng-class="{registered: !!user}" ng-switch on="!!user">
      <a ng-href="users/{{user.login}}" ng-switch-when="true">
        <img class="gravatar" ng-src="http://www.gravatar.com/avatar/{{user.gravatar_id}}?s=18&amp;d=mm">
        {{user.login}}
      </a>
  
      <span ng-switch-when="false">
        <img class="gravatar" ng-src="http://www.gravatar.com/avatar/0?s=18&amp;d=mm" src="http://www.gravatar.com/avatar/0?s=18&amp;d=mm">
        Anonymous
      </span>
    </span>
  """
  link: ($scope, $el, attrs) ->

]
      