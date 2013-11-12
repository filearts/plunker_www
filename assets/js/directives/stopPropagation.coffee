module = angular.module "plunker.directive.stopPropagation", []

module.directive "stopPropagation", ->
  restrict: "A"
  link: ($scope, $element, $attrs) ->
    previousEventName = null
    eventHandler = (e) -> e.stopPropagation()
    
    $attrs.$observe "stopPropagation", (eventName) ->
      $element.off previousEventName, eventHandler if previousEventName
      $element.on eventName, eventHandler
