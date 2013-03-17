#= require ./../services/activity

module = angular.module "plunker.cursor", [
  "plunker.activity"
]

module.service "cursor", [ "$rootScope", "activity", "visitor", ($rootScope, activity, visitor) ->
  new class Cursor
    constructor: ->
      @buffer = ""
      @position =
        row: 0
        column: 0
]