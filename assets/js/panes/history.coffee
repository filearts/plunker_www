#= require ./../services/panes
#= require ./../services/session

#= require ./../directives/inlineuser
#= require ./../directives/timeago


module = angular.module("plunker.panes")

module.requires.push "plunker.session"
module.requires.push "plunker.inlineuser"
module.requires.push "plunker.timeago"


module.run [ "panes", "session", (panes, session) ->

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
          <li class="event" ng-repeat="event in session.plunk.history">
            <i ng-class="icon(event.event)"></i>
            <plunker-inline-user user="event.user"></plunker-inline-user>
            <abbr timeago="event.created_at"></abbr>
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
      
      $scope.$watch "session.plunk.history.length", (length) ->
        pane.hidden = !length
      
]