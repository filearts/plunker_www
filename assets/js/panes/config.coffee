require "../services/multipane.coffee"
require "../services/settings.coffee"


module = angular.module "plunker.pane.config", [
  "plunker.service.settings"
]

module.run ["multipane", "settings", (multipane, settings) ->
  multipane.add "config",
    class: "icon-cogs"
    template: """
      <form role="form">
        <fieldset>
          <legend>Editor</legend>
          <div class="form-group">
            <label>Theme:</label>
            <select class="form-control" id="opts-editor-theme" ng-model="settings.editor.theme" ng-options="theme for theme in themes"></select>
          </div>
          <div class="form-group">
            <label>Tab size:</label>
            <input class="form-control" id="opts-editor-tabSize" ng-model="settings.editor.tab_size" type="number" />
          </div>
          <div class="checkbox">
            <label>
              <input class="input-mini" id="opts-editor-lineWrap" ng-model="settings.editor.wrap.enabled" type="checkbox" />
              Line wrapping
            </label>
          </div>
        </fieldset>
        <fieldset>
          <legend>Previewer</legend>
          <div class="form-group">
            <label>Refresh interval:</label>
            <input class="form-control" id="opts-previewer-delay" ng-model="settings.previewer.delay" ng-disabled="!settings.previewer.auto_refresh" type="number" />
          </div>
          <div class="checkbox">
            <label>
              <input type="checkbox" ng-model="settings.previewer.auto_refresh" />
              Auto refresh
            </label>
          </div>
        </fieldset>
      </form>
    """
    controller: ["$scope", ($scope) ->
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
]