#= require ../../vendor/select2/select2

#= require ../../vendor/angular-ui/common/module
#= require ../../vendor/angular-ui/modules/directives/select2/select2


#= require "../services/session"
#= require "../services/notifier"

#= require "../directives/inlineuser"
#= require "../directives/plunkinfo"


module = angular.module "plunker.sidebar", [
  "ui.directives"
  "plunker.session"
  "plunker.notifier"
  "plunker.inlineuser"
  "plunker.plunkinfo"
]

module.directive "plunkerSidebarFile", [ "notifier", "session", (notifier, session) ->
  restrict: "E"
  replace: true
  scope:
    buffer: "="
  template: """
    <li class="file" ng-class="{active: active}">
      <a ng-click="activateBuffer(buffer)" ng-dblclick="promptFileRename(buffer)">{{buffer.filename}}</a>
      <ul class="file-ops">
        <li class="delete">
          <button ng-click="promptFileDelete(buffer)" class="btn btn-mini">
            <i class="icon-remove"></i>
          </button>
        </li>
      </ul>
    </li>
  """
  link: ($scope, $el, attrs) ->
    buffer = $scope.buffer
    
    $scope.$watch ( -> session.getActiveBuffer() == buffer), (active) ->
      $scope.active = active
    
    $scope.activateBuffer = (buffer) ->
      session.activateBuffer(buffer.filename)
    
    $scope.promptFileRename = (buffer) ->
      notifier.prompt "Rename file", buffer.filename,
        confirm: (filename) -> session.renameBuffer(buffer.filename, filename)
    
    $scope.promptFileDelete = (buffer) ->
      notifier.confirm "Confirm Delete", "Are you sure that you would like to delete #{buffer.filename}?",
        confirm: -> session.removeBuffer(buffer.filename)
]

module.directive "plunkerTagger", ->
  restrict: "A"
  require: "ngModel"
  priority: 1
  link: ($scope, element, args, ngModel) ->
    ngModel.$parsers.push (viewValue = []) ->
      tags = []
      tags.push(option.text) for option in viewValue
      tags
      
    ngModel.$formatters.push (modelValue) ->
      options = []
      options.push(id: tag, text: tag) for tag in modelValue
      options

module.directive "plunkerSidebar", [ "session", "notifier", (session, notifier) ->
  restrict: "E"
  replace: true
  template: """
    <div class="plunker-sidebar">
      <details open>
        <summary class="header">Files</summary>
        <ul class="plunker-filelist nav nav-list">
          <plunker-sidebar-file buffer="buffer" ng-repeat="(id, buffer) in session.buffers | orderBy:'filename'">
            <a ng-click="session.activateBuffer(buffer.filename)">{{buffer.filename}}</a>
          </plunker-sidebar-file>
          <li class="newfile">
            <a ng-click="promptFileAdd()"><i class="icon-file"></i> New file</a>
          </li>
        </ul>
      </details>
      <details open>
        <summary class="header">Plunk</summary>
        <form>
          <div>
            <label for="plunk-description">
              <div>Description:</div>
              <textarea id="plunk-description" rows="4" ng-model="session.description"></textarea>
            </label>
            <label for="plunk-tags">
              <div>Tags:</div>
              <input id="plunker-tags" plunker-tagger ng-model="session.tags" ui-select2="{tokenSeparators: [',',' '], tags: [], placeholder: 'Enter tags'}" />
            </label>
            <div ng-show="session.isSaved()">
              <div>User:</div>
              <plunker-inline-user user="session.plunk.user"></plunker-inline-user>
            </div>
            <label ng-hide="session.isSaved()">
              <div>Privacy:</div>
              <input type="checkbox" ng-model="session.private" />
              <abbr title="Only users who know the url of the plunk will be able to view it">private plunk</abbr>
            </label>
            <div ng-show="session.isSaved()">
              <div>Privacy:</div>
              <abbr ng-show="session.private" title="Only users who know the url of the plunk will be able to view it"><i class="icon-lock"></i> private plunk</abbr>
              <abbr ng-hide="session.private" title="Everyone can see this plunk"><i class="icon-unlock"></i> public plunk</abbr>
            </div>
          </div>
        </form>
      </details>
    </div>
  """
  link: ($scope, $el, attrs) ->
    $scope.session = session
    $scope.promptFileAdd = ->
      notifier.prompt "New filename", "",
        confirm: (filename) -> session.addBuffer(filename, "", activate: true)
]