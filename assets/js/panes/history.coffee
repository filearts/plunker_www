#= require ./../services/panes
#= require ./../services/session
#= require ./../services/notifier

#= require ./../directives/inlineuser
#= require ./../directives/timeago


module = angular.module("plunker.panes")

module.requires.push "plunker.session"
module.requires.push "plunker.inlineuser"
module.requires.push "plunker.timeago"
module.requires.push "plunker.notifier"


module.run [ "panes", "session", "notifier", (panes, session, notifier) ->

  panes.add
    id: "history"
    icon: "undo"
    size: 230
    order: 600
    hidden: true
    title: "Change history"
    description: """
      Review previous versions of the plunk.
    """
    template: """
      <div class="plunker-history">
        <ul class="nav nav-list">
          <li class="nav-header">PLUNK HISTORY</li>
          <li class="event" ng-class="{active: $index==session.currentRevisionIndex}" ng-repeat="event in session.plunk.history | orderBy:'-created_at'">
            <a>
              <i class="type" ng-class="icon(event.event)"></i>
              <plunker-inline-user user="event.user"></plunker-inline-user>
              <abbr timeago="{{event.created_at}}"></abbr>
              <button class="btn btn-mini" ng-click="revertTo($index)"><i class="icon-undo"></i></button>
            </a>
          </li>
        </ul>
      </div>
    """
    link: ($scope, $el, attrs) ->
      pane = @
      
      $scope.session = session
      
      $scope.icon = (event) ->
        switch event
          when "create" then "icon-file"
          when "update" then "icon-save"
          when "fork" then "icon-git-fork"
          
      $scope.revertTo = (rel) ->
        return unless session.isSaved()
        
        revert = -> session.revertTo(rel)
        
        if session.isDirty() then notifier.confirm "You have unsaved changes that will be lost if you revert. Are you sure you would like to revert?",
          confirm: revert
        else revert()
      
      $scope.$watch "session.plunk.history.length", (length) ->
        pane.hidden = !length
      
]