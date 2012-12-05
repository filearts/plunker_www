#= require ../services/annotations

module = angular.module("plunker.panes")

module.requires.push "plunker.annotations"
module.requires.push "plunker.session"


module.run [ "panes", "annotations", "session", (panes, annotations, session) ->

  panes.add
    id: "linter"
    icon: "check"
    size: 328
    title: "Show lint messages"
    template: """
      <div class="plunker-linter">
        <div class="note-filters">
          <div class="btn-group">
            <button type="button" ng-click="filters.error = !filters.error" ng-class="{active: filters.error}" class="btn btn-danger">Errors</button>
            <button type="button" ng-click="filters.warning = !filters.warning" ng-class="{active: filters.warning}" class="btn btn-warning">Warnings</button>
            <button type="button" ng-click="filters.info = !filters.info" ng-class="{active: filters.info}" class="btn btn-info">Information</button>
          </div>
        </div>
        <section ng-repeat="(buffId, notes) in annotations">
          <h4>{{session.buffers[buffId].filename}}</h4>
          <ul class="notes-list">
            <li ng-hide="relevantNotes(notes, filters).length" class="alert alert-success">
              No matching notes
            </li>
            <li ng-repeat="note in relevantNotes(notes, filters)" class="alert alert-{{note.type}}">
              <a ng-click="positionCursor(note.row, note.column)" class="note-line">Line {{note.row}}</a>
              <p class="note-text" ng-bind="note.text"></p>
            </li>
          </ul>
        </section>
      </div>
    """
    link: ($scope, $el, attrs) ->
      pane = @
      
      $scope.annotations = annotations
      $scope.session = session
      $scope.notesUpdated = false
      $scope.filters =
        error: true
        warning: true
        info: false
      
      $scope.relevantNotes = (input, filters) ->
        output = []
        
        for note in input
          output.push note if filters[note.type]
        
        output
        
      $scope.$watch "pane.active", (active) ->
        pane.class = "" if active
      
      $scope.$watch "annotations", (annotations) ->
        unless pane.active
          for buffId, notes of annotations
            if $scope.relevantNotes(notes, $scope.filters).length
              pane.class = "pulse-info"
              return
      , true
      
]