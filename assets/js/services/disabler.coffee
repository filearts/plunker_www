module = angular.module "plunker.service.disabler", []

module.directive "plunkerDisabler", ["disabler", (disabler) ->
  link: ($scope, $element, $attrs) ->
    mask = angular.element """
      <div class="plunker-disabler"></div>
    """

    $scope.$watch ( -> disabler.state[$attrs.plunkerDisabler]), (state, prev) ->
      if state then $element.append(mask)
      else mask.remove()
]

module.factory "disabler", [ "$q", ($q) ->
  queues = {}
  
  @state = {}
  @enqueue = (name, valueOrPromise) ->
    disabler = @
    
    disabler.state[name] = true
    $q.when(valueOrPromise).finally ->
      disabler.state[name] = false
    
    valueOrPromise
  
  return @
]