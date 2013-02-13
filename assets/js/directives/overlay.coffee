module = angular.module "plunker.overlay", []

module.directive "overlay", [ "$rootScope", "overlay", ($rootScope, overlay) ->
  restrict: "C"
  replace: true
  template: """
    <div ng-show="overlay.message">
      <p class="message" ng-bind="overlay.message"></p>
    </div>
  """
  link: ($scope, $el, attrs) ->
    $scope.overlay = overlay
]

module.service "overlay", [ "$q", ($q) ->

  # Our queue of promises starts as a single truthy value
  messages = []
  
  new class Overlay
    constructor: (@message = "Starting up", @queue) ->
    
    remover: (message) =>
      messages.push message
      =>
        unless 0 > idx = messages.indexOf(message)
          messages.splice idx, 1
          @message = messages[messages.length - 1]
  
    show: (@message, promise) ->
      resolver = @remover(@message)
      
      @queue = $q.all [ @queue, promise.then(resolver, resolver) ]
]

module.run [ "$rootScope", "$q", "overlay", ($rootScope, $q, overlay) ->
  
  routeChangePromise = null
  
  $rootScope.$on "$routeChangeStart", ->
    dfd = $q.defer()
    
    finished = (method) ->
      ->
        deregSuccess()
        deregError()
        
        dfd[method]()
    
    deregSuccess = $rootScope.$on "$routeChangeSuccess", finished("resolve")
    deregError = $rootScope.$on "$routeChangeError", finished("reject")
      
    overlay.show "Loading...", dfd.promise

  
]