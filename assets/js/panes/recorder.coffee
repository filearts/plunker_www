#= require ../services/panes
#= require ../services/activity
#= require ../services/session


#= require ../directives/player

module = angular.module("plunker.panes")

module.requires.push "plunker.activity"
module.requires.push "plunker.session"
module.requires.push "plunker.notifier"
module.requires.push "plunker.player"


module.run [ "$timeout", "panes", "activity", "session", "notifier", ($timeout, panes, activity, session, notifier) ->

  panes.add
    id: "recorder"
    icon: "facetime-video"
    size: 328
    order: 400
    title: "Session Recorder"
    hidden: true
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
        <button class="btn btn-primary" ng-click="promptSave()" ng-show="!recording && events.length">
          <i class="icon-save"></i>
          Save
        </button>
        <button class="btn btn-danger" ng-click="promptReset()" ng-show="!recording && events.length">
          <i class="icon-eject"></i>
          Reset
        </button>
        <plunker-player events="events" ng-show="events.length && !recording"></plunker-player>
      </div>
    """
    link: ($scope, $el, attrs) ->
      stopListening = null
      
      $scope.startRecording = ->
        $scope.recording = Date.now()
        
        $scope.events.length = 0
        $scope.events.push
          time: 0
          type: "reset"
          event: session.toJSON(includeBufferId: true)
        
        stopListening = activity.client("recorder").watch (type, event) ->
          $scope.events.push
            time: Date.now() - $scope.recording
            type: type
            event: event
      
      $scope.stopRecording = ->
        stopListening()
        
        $scope.recording = 0 # Kill the listener
        $scope.final = session.toJSON()
      
      $scope.reset = ->
        $scope.playing = 0
        $scope.events = []
        $scope.final = null

      $scope.promptReset = ->
        notifier.confirm "This will cause your session recording to be lost. Are you sure you would like to reset the recorder?",
          confirm: $scope.reset
      
      $scope.promptSave = ->
        notifier.confirm "Are you sure that you would like to attach this recording to your Plunk?",
          confirm: -> session.addBuffer "recording.json", JSON.stringify($scope.events)
      
      $scope.reset()
]