require "../services/session.coffee"
require "../services/notifier.coffee"


module = angular.module "plunker.service.dirty", [
  "plunker.service.session"
  "plunker.service.notifier"
]

module.factory "dirty", [ "session", (session) ->
  client = session.createClient("plunker.service.dirty")
  dirty = false
  
  client.on "reset", (e, snapshot) -> dirty = true
  client.on "fileCreate", (e, snapshot) -> dirty = true
  client.on "fileRemove", (e, snapshot) -> dirty = true
  client.on "fileRename", (e, snapshot) -> dirty = true
  client.on "textInsert", (e, snapshot) -> dirty = true
  client.on "textRemove", (e, snapshot) -> dirty = true
  
  markClean: -> dirty = false
  
  markDirty: ->
    dirty = true
  
  isClean: -> !@isDirty
  isDirty: -> dirty
]

module.run ["$rootScope", "$state", "$location", "dirty", "notifier", ($rootScope, $state, $location, dirty, notifier) ->
  window.onbeforeunload = -> "You have unsaved changes. Are you sure you would like to leave this page?" if dirty.isDirty()  

  $rootScope.$on "$stateChangeStart", (e, toState, toParams, fromState, fromParams) ->
    if $state.includes("editor") and dirty.isDirty()
      e.preventDefault()
      
      $location.path($state.href(fromState, fromParams)).replace()
      
      notifier.confirm("You have unsaved changes. Are you would like to proceed?").then (answer) ->
        if answer
          # Mark as clean to avoid future prompts
          dirty.markClean()
          $state.transitionTo(toState, toParams)


]