#= require ../services/settings

module = angular.module("plunker.panes")

module.requires.push "plunker.settings"


module.run [ "panes", "settings", (panes, settings) ->

  panes.add
    id: "options"
    icon: "cog"
    size: 328
    order: 1000
    title: "Personalize the editor"
    template: """
      <div class="plunker-options">
        <form class="form-horizontal">
          <h4>Editor:</h4>
          <div class="control-group">
            <label class="control-label" for="opts-editor-theme">Theme:</label>
            <div class="controls">
              <select class="input-medium" id="opts-editor-theme" ng-model="settings.editor.theme" ng-options="theme for theme in themes"></select>
            </div>
          </div>
          <div class="control-group">
            <label class="control-label" for="opts-editor-tabSize">Tab size:</label>
            <div class="controls">
              <input class="input-mini" id="opts-editor-tabSize" ng-model="settings.editor.tab_size" type="number" />
            </div>
          </div>
          <hr />
          <h4>Previewer:</h4>
          <div class="control-group">
            <label class="control-label" for="opts-previewer-delay">Refresh interval:</label>
            <div class="controls">
              <input class="input-small" id="opts-previewer-delay" ng-model="settings.previewer.delay" ng-disabled="!settings.previewer.auto_refresh" type="number" />
              <label class="checkbox">
                <input type="checkbox" ng-model="settings.previewer.auto_refresh" />
                Auto refresh
              </label>
            </div>
          </div>
        </form>
      </div>
    """
    link: ($scope, $el, attrs) ->
      $scope.settings = settings
      $scope.themes = [
        "ambiance"
        "chrome"
        "clouds"
        "clouds_midnight"
        "crimson_editor"
        "dawn"
        "dreamweaver"
        "eclipse"
        "github"
        "idle_fingers"
        "kr_theme"
        "merbivore"
        "merbivore_soft"
        "monokai"
        "pastel_on_dark"
        "solarized_dark"
        "solarized_light"
        "textmate"
        "tomorrow"
        "tomorrow_night"
        "tomorrow_night_blue"
        "tomorrow_night_bright"
        "twilight"
        "vibrant_ink"
        "xcode"
      ]
]