#= require ../services/panes
#= require ../services/activity
#= require ../services/session

module = angular.module("plunker.panes")

module.requires.push "plunker.activity"
module.requires.push "plunker.session"
module.requires.push "plunker.notifier"


module.directive "plunkerPlayer", [ "$timeout", "activity", ($timeout, activity) ->
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
            activity.play(current.type, current.path, current.args...)
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
    
]

module.run [ "$timeout", "panes", "activity", "session", "notifier", ($timeout, panes, activity, session, notifier) ->

  panes.add
    id: "recorder"
    icon: "facetime-video"
    size: 328
    order: 400
    title: "Session Recorder"
    description: """
      Record all of your activities while you are working on your plunker and share them with other users.
    """
    template: """
      <div class="plunker-recorder">
        <button class="btn btn-success" ng-click="startRecording()" ng-show="!recording && !events.length">
          <i class="icon-play-circle"></i>
          Start recording
        </button>
        <button class="btn btn-success" ng-click="stopRecording()" ng-show="recording">
          <i class="icon-stop"></i>
          Finish recording
        </button>
        <button class="btn btn-danger" ng-click="promptReset()" ng-show="!recording && events.length">
          <i class="icon-eject"></i>
          Reset
        </button>
        <plunker-player events="events"></plunker-player>
        <ul>
          <li ng-class="{active: $index==$parent.lastEvent}" ng-repeat="event in events">{{event.time}} - {{event.type}}</li>
        </ul>
      </div>
    """
    link: ($scope, $el, attrs) ->
      stopListening = null

      $scope.recording = 0
      $scope.events = []
      
      $scope.startRecording = ->
        $scope.recording = Date.now()
        
        $scope.events.length = 0
        $scope.events.push
          time: 0
          type: "reset"
          path: []
          args: [session.toJSON(includeBufferId: true)]
        
        stopListening = activity.addWatcher (event, path, args...) ->
          $scope.events.push
            time: Date.now() - $scope.recording
            type: event
            path: path
            args: args
      
      $scope.stopRecording = ->
        stopListening()
        
        $scope.recording = 0 # Kill the listener
        $scope.lastEvent = -1
        
        $scope.final = session.toJSON()
      
      $scope.reset = ->
        $scope.playing = 0
        $scope.lastEvent = -1
        $scope.events = []

      $scope.promptReset = ->
        notifier.confirm "This will cause your session recording to be lost. Are you sure you would like to reset the recorder?",
          confirm: $scope.reset
]