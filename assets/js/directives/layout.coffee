#= require "../../vendor/jquery-ui"
#= require "../../vendor/jquery-layout/jquery.layout"

#= require "../directives/sidebar"
#= require "../directives/ace"

module = angular.module "plunker.layout", ["plunker.sidebar", "plunker.ace"]

module.directive "plunkerEditorLayout", [ () ->
  restrict: "E"
  replace: true
  template: """
    <div class="plunker-editor-layout">
      <div class="ui-layout-west">
        <plunker-sidebar></plunker-sidebar>
      </div>
      <div class="ui-layout-center">
        <div class="ui-layout-center">
          <plunker-ace></plunker-ace>
        </div>
        <div class="ui-layout-east"></div>
      </div>
      <div class="ui-layout-east">
        
      </div>
    </div>
  """
  link: ($scope, $el, attrs) ->
    $el.layout
      defaults:
        spacing_open: 4
        spacing_closed: 8
        onresize: -> $scope.$broadcast "resize", arguments...
      west:
        size: 160
        minSize: 160
        maxSize: 320
      center:
        children:
          defaults:
            spacing_open: 4
            spacing_closed: 8
          center:
            size: "50%"
          east:
            initHidden: true
            size: "50%"
      east:
        size: 41 # 40px + 1px border
        closable: false
        resizable: false
        spacing_open: 1
        spacing_closed: 1
]