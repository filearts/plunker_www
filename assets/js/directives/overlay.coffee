module = angular.module "plunker.overlay", []

module.directive "overlay", [ "$rootScope", "$route", ($rootScope, $route) ->
  restrict: "C"
  link: ($scope, $el, attrs) ->
    $message = $el.find(".message")
    
    $rootScope.$on "$routeChangeStart", ->
      $el.addClass("show")
      $message.text("Loading...")
    
    $rootScope.$on "$routeChangeSuccess", (curr, prev) ->
      $el.removeClass("show")
      $message.text("")

    $rootScope.$on "$routeChangeError", (curr, prev) ->
      $el.removeClass("show")
      $message.text("")
]
      