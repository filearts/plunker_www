require "../../vendor/angular-ui/ui-bootstrap"

require "../services/notifier.coffee"

module = angular.module "plunker.directive.toolbar", [
  "ui.bootstrap"
  
  "plunker.service.notifier"
]

module.directive "plunkerToolbar", [ "$state", "session", "notifier", ($state, session, notifier) ->
  restrict: "E"
  replace: true
  scope: true
  template: """
    <div class="plunker-editor-toolbar">
      <div class="pull-left">
        <button class="btn btn-sm btn-primary" ng-click="save()">
          Save
        </button>
        
        <button class="btn btn-sm btn-success" ui-sref="editor">
          New
        </button>
        
        <button class="btn btn-sm btn-info" ng-class="{active: showPreviewPane}" ng-click="togglePreviewPane()">
          Preview
        </button>
      </div>
      <div class="pull-right">
        <div class="btn-group btn-sm" ng-controller="LayoutController">
          <button class="btn btn-sm btn-default" ng-click="layout.setLayout($index)" ng-repeat="preset in layout.presets" ng-bind="$index" tooltip="{{preset.name}}" tooltip-append-to-body="true" tooltip-placement="bottom"></button>
        </div>
      </div>
    </div>
  """
  
  link: ($scope, $element, $attrs) ->
    client = session.createClient("directive.toolbar")
    
    $scope.save = ->
      notifier.warn "Save not implemented... yet"
]