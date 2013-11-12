require "../../vendor/angular-ui/ui-bootstrap"

require "../services/notifier.coffee"
require "../services/layout.coffee"
require "../services/oauth.coffee"
require "../services/visitor.coffee"
require "../services/project.coffee"


module = angular.module "plunker.directive.toolbar", [
  "ui.bootstrap"
  
  "plunker.service.notifier"
  "plunker.service.layout"
  "plunker.service.oauth"
  "plunker.service.visitor"
  "plunker.service.project"
]

module.directive "plunkerToolbar", [ "$state", "session", "notifier", "layout", "oauth", "visitor", "project", ($state, session, notifier, layout, oauth, visitor, project) ->
  restrict: "E"
  replace: true
  scope: true
  template: """
    <div class="plunker-editor-toolbar">
      <div class="pull-left">
        <a class="plunker-brand" href="/">Plunker <sub class="version">1.7.0</sub></a>
      </div>
      <div class="pull-left toolbar-block">
        <button class="btn btn-sm btn-primary" ng-class="{disabled: !project.canSave()}" ng-click="save()">
          Save
        </button>
        
        <div class="btn-group" ng-if="project.isSaved()">
          <button class="btn btn-sm btn-default">
            Fork
          </button>
          <button class="btn btn-sm btn-default dropdown-toggle">
            <span class="caret"></span>
          </button>
          <ul class="dropdown-menu">
            <li ng-if="project.isPublic()"><a>Fork as private</a></li>
            <li ng-if="!project.isPublic()"><a>Fork as public</a></li>
          </ul>
        </div>
        
        <button class="btn btn-sm btn-success" ui-sref="editor.reset" tooltip="Start a new plunk and open the templates pane" tooltip-append-to-body="true" tooltip-placement="bottom">
          New
        </button>
        
        <button class="btn btn-sm btn-info" ng-class="{active: !layout.current.preview.closed}" ng-click="layout.current.preview.closed = !!!layout.current.preview.closed">
          Preview
        </button>
      </div>
      <div class="pull-right toolbar-block">
        <div class="btn-group btn-sm" ng-controller="LayoutController">
          <button class="btn btn-sm btn-default" ng-click="layout.setLayout($index)" ng-class="{active: $index==layout.currentIndex}" ng-repeat="preset in layout.presets" ng-bind="$index" tooltip="{{preset.name}}" tooltip-append-to-body="true" tooltip-placement="bottom"></button>
        </div>
        <div class="btn-group btn-sm" ng-if="!visitor.session.user">
          <button class="btn btn-sm btn-default" ng-disabled="disableLogin" ng-class="{disabled: ngDisableLogin}" ng-click="login()" tooltip="Login using Github" tooltip-append-to-body="true" tooltip-placement="bottom">Login</button>
        </div>
        <div class="btn-group btn-sm" ng-if="visitor.session.user">
          <button class="btn btn-sm btn-default dropdown-toggle" ng-disabled="disableLogout" ng-class="{disabled: disableLogout}">
            <img class="gravatar" ng-src="http://www.gravatar.com/avatar/{{visitor.session.user.gravatar_id}}?s=20">
            <span ng-bind="visitor.session.user.login"></span>
            <span class="caret">
          </button>
          <ul class="dropdown-menu pull-right">
            <li><a ng-click="logout()">Logout</a></li>
          </ul>
        </div>
      </div>
    </div>
  """
  
  link: ($scope, $element, $attrs) ->
    client = session.createClient("directive.toolbar")
    
    $scope.visitor = visitor
    $scope.project = project
    
    $scope.save = ->
      notifier.warn "Save not implemented... yet"
    
    $scope.login = ->
      $scope.disableLogin = true
      login = oauth.authenticate().then (authInfo) ->
        visitor.login(authInfo)
      
      login.finally ->
        $scope.disableLogin = false
    
    $scope.logout = ->
      $scope.disableLogout = true
      logout = visitor.logout()
      logout.finally ->
        $scope.disableLogout = false
]