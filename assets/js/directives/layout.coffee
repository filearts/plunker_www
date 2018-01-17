#= require jquery-ui
#= require jquery-layout/jquery.layout

#= require ./../services/panes

#= require ./../directives/sidebar
#= require ./../directives/ace
#= require ./../directives/multipane
#= require ./../directives/paneselector

#= require_tree ./../panes

module = angular.module "plunker.layout", [
  "plunker.panes"
  "plunker.sidebar"
  "plunker.ace"
  "plunker.multipane"
  "plunker.paneselector"
]

module.directive "plunkerEditorLayout", [ "panes", (panes) ->
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
        <plunker-multipane class="ui-layout-east"></plunker-multipane>
      </div>
      <plunker-paneselector class="ui-layout-east">
      </plunker-paneselector>
    </div>
  """
  link: ($scope, $el, attrs) ->
    layout = $el.layout
      defaults:
        spacing_open: 4
        spacing_closed: 8
        onresize: -> $scope.$broadcast "resize", arguments...
      west:
        size: 250
        minSize: 200
        maxSize: 320
        onresize: -> $scope.$broadcast "resize", arguments...
      center:
        children:
          defaults:
            spacing_open: 4
            spacing_closed: 0
            onresize: -> $scope.$broadcast "resize", arguments...
          center:
            size: "50%"
          east:
            maskContents: true
            onresize: (el, name, state) ->
              panes.active.size = state.size if panes.active
            onclose: ->
              if panes.active then $scope.$apply ->
                panes.close()
      east:
        size: 41 # 40px + 1px border
        closable: false
        resizable: false
        spacing_open: 1
        spacing_closed: 1

    center = layout.panes.center.layout()
    center.resizers.east.mousedown -> center.showMasks("east")
    center.resizers.east.mouseup -> center.hideMasks("east")

    # Watch for changes to the active pane
    $scope.$watch ( -> panes.active ), (pane) ->
      if pane
        center.sizePane("east", pane.size)
        center.open("east")
      else center.close("east")

]
