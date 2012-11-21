#= require "../../vendor/jquery-ui"
#= require "../../vendor/jquery-layout/jquery.layout"

#= require "../directives/ace"

module = angular.module "plunker.layout", ["plunker.ace"]

module.directive "plunkerEditorLayout", [ () ->
  restrict: "E"
  replace: true
  template: """
    <div class="plunker-editor-layout">
      <div class="ui-layout-west"></div>
      <div class="ui-layout-center">
        <div class="ui-layout-center">
          <plunker-ace></plunker-ace>
        </div>
        <div class="ui-layout-east"></div>
      </div>
    </div>
  """
  link: ($scope, $el, attrs) ->
    $el.layout
      defaults:
        onresize: -> $scope.$broadcast "resize", arguments...
      west:
        size: 200
        minSize: 150
        maxSize: 300
      center:
        children:
          center:
            size: "50%"
          east:
            size: "50%"
]