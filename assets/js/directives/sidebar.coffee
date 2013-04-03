#= require ./../../vendor/select2/select2

#= require ./../../vendor/jquery.autosize/jquery.autosize

#= require ./../../vendor/angular-ui/common/module
#= require ./../../vendor/angular-ui/modules/directives/select2/select2

#= require ./../../vendor/ui-bootstrap/ui-bootstrap-tpls-0.2.0

#= require ./../../vendor/script/dist/script


#= require ./../services/session
#= require ./../services/notifier

#= require ./../directives/inlineuser
#= require ./../directives/plunkinfo
#= require ./../directives/restorer


module = angular.module "plunker.sidebar", [
  "plunker.session"
  "plunker.notifier"
  "plunker.inlineuser"
  "plunker.plunkinfo"
  "plunker.restorer"
  "ui.directives"
  "ui.bootstrap"
]

module.directive "plunkerSidebarFile", [ "notifier", "session", (notifier, session) ->
  restrict: "E"
  replace: true
  scope:
    buffer: "="
  template: """
    <li class="file" ng-class="{active: active, dirty: dirty, changed: changed}">
      <ul class="participants">
        <li ng-class="participant.style" ng-repeat="(id, participant) in buffer.participants" title="{{participant.handle}}">
        </li>
      </ul>
      <a class="filename" ng-click="activateBuffer(buffer)" ng-dblclick="promptFileRename(buffer)">{{buffer.filename}}</a>
      <ul class="file-ops">
        <li class="delete">
          <button ng-click="promptFileDelete(buffer)" class="btn btn-mini" tooltip="Delete this file" tooltip-placement="right">
            <i class="icon-remove"></i>
          </button>
        </li>
      </ul>
    </li>
  """
  link: ($scope, $el, attrs) ->
    buffer = $scope.buffer
    
    $scope.$watch ( -> session.isDirty(["buffers", buffer.id])), (dirty) ->
      $scope.dirty = dirty and Date.now()
      $scope.changed = dirty and not $scope.active
    
    $scope.$watch ( -> session.getActiveBuffer() == buffer), (active) ->
      $scope.active = active and Date.now()
      $scope.changed = false
    
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
      <plunker-restorer></plunker-restorer>
      <details open>
        <summary class="header">Files</summary>
        <ul class="plunker-filelist nav nav-list">
          <plunker-sidebar-file buffer="buffer" ng-repeat="(id, buffer) in session.buffers">
          </plunker-sidebar-file>
          <li class="newfile">
            <a ng-click="promptFileAdd()">
              <i class="icon-file"></i> New file
            </a>
          </li>
        </ul>
      </details>
      <details open>
        <summary class="header">Plunk</summary>
        <form>
          <div>
            <label for="plunk-description">
              <div>Description:</div>
              <textarea id="plunk-description" rows="2" ng-model="session.description"></textarea>
            </label>
            <label for="plunk-tags">
              <div>Tags:</div>
              <input id="plunker-tags" plunker-tagger ng-model="session.tags" ui-select2="{tokenSeparators: [',',' '], tags: [], placeholder: 'Enter tags'}" />
            </label>
            <div ng-show="session.isSaved()">
              <div>User:</div>
              <plunker-inline-user user="session.plunk.user"></plunker-inline-user>
            </div>
            <div ng-hide="session.isSaved()">
              <div>Privacy:</div>
              <label>
                <span tooltip="Only users who know the url of the plunk will be able to view it" tooltip-placement="right">
                  <input type="checkbox" ng-model="session.private" />
                  private plunk
                </span>
              </label>
            </div>
            <div ng-show="session.isSaved()">
              <div>Privacy:</div>
              <abbr ng-show="session.private" title="Only users who know the url of the plunk will be able to view it"><i class="icon-lock"></i> private plunk</abbr>
              <abbr ng-hide="session.private" title="Everyone can see this plunk"><i class="icon-unlock"></i> public plunk</abbr>
            </div>
            <div class="share" ng-show="session.isSaved()">
              <div id="sidebar-share" class="addthis_toolbox addthis_default_style" ng-show="addthis">
                <a class="addthis_button_preferred_1"></a>
                <a class="addthis_button_preferred_2"></a>
                <a class="addthis_button_preferred_3"></a>
                <a class="addthis_button_compact"></a>
                <a class="addthis_counter addthis_bubble_style"></a>
              </div>
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
    $desc = $el.find("#plunk-description")
    $desc.autosize(append: "\n")

    window.addthis_config =
      data_track_clickback: true
      data_ga_property: 'UA-28928507-1'
      data_ga_social: true
    
    window.addthis_share =
      title: "Check out what I made on Plunker"

    $scope.$watch "session.description", (description) ->
      $desc.trigger("autosize")
      
      window.addthis_share.description = description
    $scope.$on "resize", -> $desc.trigger("autosize")
    
    $(".share").on "click", (e) ->
      e.stopPropagation()
      e.preventDefault()
    
    dereg = $scope.$watch "session.isSaved()", (saved) ->

      
      if saved
        $script "//s7.addthis.com/js/300/addthis_widget.js#pubid=ra-4f60c7714e5b5629", "addthis"
        $script.ready "addthis", ->
          $scope.$apply ->
            $scope.addthis = true
          
          dereg()
]