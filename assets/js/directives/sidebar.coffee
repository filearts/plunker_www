#= require select2/select2

#= require jquery.autosize/jquery.autosize

#= require ui-bootstrap/ui-bootstrap-tpls-0.3.0

#= require script/dist/script


#= require ./../services/session
#= require ./../services/notifier
#= require ./../services/url
#= require ./../services/visitor

#= require ./../directives/addthis
#= require ./../directives/inlineuser
#= require ./../directives/plunkinfo
#= require ./../directives/restorer
#= require ./../directives/overlay


module = angular.module "plunker.sidebar", [
  "plunker.addthis"
  "plunker.session"
  "plunker.notifier"
  "plunker.inlineuser"
  "plunker.plunkinfo"
  "plunker.restorer"
  "plunker.visitor"
  "plunker.overlay"
  "plunker.url"
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
      <a class="filename" ng-click="activateBuffer(buffer)" ng-dblclick="promptFileRename(buffer) | trackEvent:'File':'Rename':'Sidebar'">{{buffer.filename}}</a>
      <ul class="file-ops">
        <li class="delete">
          <button ng-click="promptFileDelete(buffer) | trackEvent:'File':'Delete':'Sidebar'" class="btn btn-mini" tooltip="Delete this file" tooltip-placement="right">
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

module.directive "plunkerTagger", ["$timeout", "url", ($timeout, url) ->
  restrict: "E"
  replace: true
  require: "ngModel"
  template: """
    <input type="hidden" ng-list>
  """
  link: ($scope, element, args, ngModel) ->
    modelChange = false
    
    $select2 = $(element).select2
      tags: []
      minimumInputLength: 1
      tokenSeparators: [',',' ']
      placeholder: 'Enter tags'
      initSelection: (el, cb) ->
        cb({id: tag, text: tag} for tag in ngModel.$modelValue)
      createSearchChoice: (term, data) ->
        return null for item in data when item.text?.localeCompare(term) == 0
        
        id: term,
        text: term
      query: (query) ->
        $.getJSON "#{url.api}/tags", {q: query.term}, (data) ->
          results = []
          results.push {id: item.tag, text: item.tag} for item in data
          
          query.callback results: results
    
    $select2.on "change", (e) ->
      unless modelChange then $scope.$apply ->
        ngModel.$setViewValue(e.val.join(","))
    
    ngModel.$render = ->
      modelChange = true
      $(element).select2("val", ngModel.$modelValue)
      modelChange = false
]

module.filter "eventIcon", ->
  (event) ->
    switch event
      when "create" then "icon-file"
      when "update" then "icon-save"
      when "fork" then "icon-git-fork"

module.filter "eventName", ->
  (event) ->
    switch event
      when "create" then "Created"
      when "update" then "Updated"
      when "fork" then "Forked"

module.directive "plunkerSidebar", [ "$timeout", "$q", "session", "notifier", "visitor", "overlay", ($timeout, $q, session, notifier, visitor, overlay) ->
  restrict: "E"
  replace: true
  template: """
    <div class="plunker-sidebar">
      <plunker-restorer></plunker-restorer>
      <div class="share" ng-switch="session.isSaved()">
        <div ng-switch-when="true" addthis-toolbox class="addthis_default_style addthis_20x20_style" addthis-description="{{session.description}}">
          <a target="_self" class="addthis_button_twitter"></a>
          <a target="_self" class="addthis_button_facebook"></a>
          <a target="_self" class="addthis_button_google_plusone_share"></a>
          <a target="_self" class="addthis_button_linkedin"></a>
          <a target="_self" class="addthis_button_compact"></a>
        </div>
      </div>
      <details open>
        <summary class="header">Files</summary>
        <ul class="plunker-filelist nav nav-list">
          <plunker-sidebar-file buffer="buffer" ng-repeat="buffer in session.getBufferArray() | orderBy:'filename'">
          </plunker-sidebar-file>
          <li class="newfile">
            <a ng-click="promptFileAdd() | trackEvent:'File':'Add':'Sidebar'">
              <i class="icon-file"></i> New file
            </a>
          </li>
        </ul>
      </details>
      <details ng-show="session.isSaved()">
        <summary class="header">Versions <span class="label" ng-bind="session.plunk.history.length | number"></span></summary>
        <ul class="plunker-filelist nav nav-list">
          <li ng-class="{active: $index==session.currentRevisionIndex, frozen: $index==session.plunk.frozen_version}" ng-repeat="event in session.plunk.history | orderBy:'-created_at'">
            <a ng-click="revertTo($index) | trackEvent:'Plunk':'Revert':'Sidebar'">
              <i ng-class="event.event | eventIcon"></i>
              <span ng-bind="event.event | eventName"></span>
              <abbr timeago="{{event.created_at}}"></abbr>
              <i class="icon-lock" ng-show="session.plunk.frozen_at && $index==session.plunk.history.length - 1 - session.plunk.frozen_version" tooltip="The plunk is currently frozen at this version" tooltip-placement="right"></i>
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
              <plunker-tagger id="plunker-tags" ng-model="session.tags" />
            </label>
            <div ng-show="session.isSaved()">
              <div>User:</div>
              <plunker-inline-user user="session.plunk.user"></plunker-inline-user>
            </div>
            <div ng-hide="session.isSaved() || !visitor.isMember()">
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
              <abbr ng-show="session.plunk.private" tooltip-placement="right" tooltip="Only users who know the url of the plunk will be able to view it"><i class="icon-lock"></i> private plunk</abbr>
              <abbr ng-hide="session.plunk.private" tooltip-placement="right" tooltip="Everyone can see this plunk"><i class="icon-unlock"></i> public plunk</abbr>
            </div>
          </div>
        </form>
      </details>
    </div>
  """
  link: ($scope, $el, attrs) ->
    $scope.session = session
    $scope.visitor = visitor
    $scope.promptFileAdd = ->
      notifier.prompt "New filename", "",
        confirm: (filename) -> session.addBuffer(filename, "", activate: true)

    $scope.revertTo = (rel) ->
      return unless session.isSaved()
                                    
      revert = ->
        overlay.show "Reverting plunk", session.revertTo(rel)
      
      if session.isDirty() then notifier.confirm "You have unsaved changes that will be lost if you revert. Are you sure you would like to revert?",
        confirm: revert
      else revert()

    $desc = $el.find("#plunk-description")
    $desc.autosize(append: "\n")

    #window.addthis_config =
    #  data_track_clickback: false
    #  data_ga_property: 'UA-28928507-5'
    #  data_ga_social: true

    $scope.$watch "session.description", (description) ->
      $desc.trigger("autosize")
      
    $scope.$on "resize", -> $desc.trigger("autosize")
    
    $(".share").on "click", (e) ->
      e.stopPropagation()
      e.preventDefault()
    
]