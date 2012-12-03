module = angular.module "plunker.overlay", []

module.directive "overlay", [ "$rootScope", ($rootScope) ->
  restrict: "C"
  link: ($scope, $el, attrs) ->
    $message = $el.find(".message")
    
    $rootScope.$on "$routeChangeStart", ->
      $el.addClass("show")
      $message.text("Loading...")
    
    $rootScope.$on "$routeChangeSuccess", ->
      $el.removeClass("show")
      $message.text("")
]
      