module = angular.module "plunker.overlay", []

module.directive "overlay", [ "$rootScope", ($rootScope) ->
  restrict: "C"
  link: ($scope, $el, attrs) ->
    console.log "Linked to", $el
    $rootScope.$on "$routeChangeStart", ->
      console.log "Handing route change"
      $el.addClass("show")
      $el.text("Loading page...")
    
    $rootScope.$on "$routeChangeSuccess", ->
      console.log "Route change finished"
      $el.removeClass("show")
      $el.text("")
]
      