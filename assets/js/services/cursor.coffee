module = angular.module "plunker.cursor", []

module.service "cursor", [ () ->
  new class Cursor
    constructor: ->
      @filename = ""
      @position =
        row: 0
        column: 0
]