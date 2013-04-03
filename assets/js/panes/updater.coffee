#= require ./../services/updater
#= require ./../services/session


module = angular.module("plunker.panes")

module.requires.push "plunker.updater"
module.requires.push "plunker.session"


module.run [ "panes", "session", "updater", (panes, session, updater) ->

  panes.add
    id: "updater"
    icon: "magic"
    size: 230
    order: 600
    hidden: true
    title: "Updater"
    description: """
      Review previous versions of the plunk.
    """
    template: """
      <div class="plunker-history">
        <button ng-click="update()">Update</button>
      </div>
    """
    link: ($scope, $el, attrs) ->
      pane = @
      
      $scope.update = ->
        updater.update(session.activeBuffer.content).then (markup) ->
          session.activeBuffer.content = markup
      
]