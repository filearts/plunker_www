#= require ../services/activity
#= require ../services/session


module = angular.module "plunker.player", [
  "plunker.activity"
  "plunker.session"
]

module.directive "plunkerPlayer", [ "$timeout", "activity", "session", ($timeout, activity, session) ->
  restrict: "E"
  replace: true
  scope:
    events: "="
    final: "="
    
  template: """
    <div class="plunker-player">
      <div class="btn-toolbar">
        <div class="btn-group">
          <button class="btn btn-small" ng-click="seekStart()" title="Return to the start of the recorded session" ng-disabled="currentEvent==0"><i class="icon-fast-backward"></i></button>
          <button class="btn btn-small" ng-click="addSpeed(-1)" title="Decrease the playback speed to {{speed - 1}}x" ng-disabled="!events.length || speed<=0"><i class="icon-backward"></i></button>
          <button class="btn btn-small" ng-click="play()" ng-hide="playing" ng-disabled="currentEvent==events.length"><i class="icon-play"></i></button>
          <button class="btn btn-small" ng-click="pause()" ng-show="playing"><i class="icon-pause"></i></button>
          <button class="btn btn-small" ng-click="stepForward()" ng-disabled="playing || currentEvent==events.length"><i class="icon-step-forward"></i></button>
          <button class="btn btn-small" ng-click="addSpeed(1)" ng-disabled="!events.length"><i class="icon-forward"></i></button>
          <button class="btn btn-small" ng-click="seekEnd()" ng-disabled="currentEvent==events.length"><i class="icon-fast-forward"></i></button>
        </div>
      </div>
      <ul class="nav nav-list">
        <li ng-class="{active: $index==currentEvent}" ng-repeat="event in events">
          <a>{{event.time}} - {{event.type}}</a>
        </li>
      </ul>
    </div>
  """
  link: ($scope, $el, attrs) ->
    nextEventPromise = null
    
    $scope.speed = 1
    $scope.playing = false
    
    $scope.seekStart = ->
      $scope.currentEvent = 0
      $scope.stepForward = ->
        if current = $scope.events[$scope.currentEvent]
          $timeout ->
            activity.client("recorder").playback(current.type, current.event)
            $scope.currentEvent++
            
            if $scope.playing
              if next = $scope.events[$scope.currentEvent]
                nextEventPromise = $timeout($scope.stepForward, (next.time - current.time) / ($scope.speed or 1))
              else
                $scope.playing = false
          , 0, false
            
    $scope.play = ->
      $scope.playing = true
      $scope.stepForward()
      
    $scope.pause = ->
      $timeout.cancel(nextEventPromise) if nextEventPromise
      $scope.playing = false
    
    $scope.addSpeed = (increment = 0) ->
      $scope.speed = Math.max(1, $scope.speed + increment)
      
    $scope.seekStart()
    
    $scope.$watch "playing", (playing) ->
      session.readonly = !!playing
    
]