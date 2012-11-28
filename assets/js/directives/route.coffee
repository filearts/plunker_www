module = angular.module "plunker.route", []

module.directive "plunkerRouteIgnore", [ "$location", ($location) ->
  restrict: "A"
  replace: true
  #scope:
  #  href: "@"
  link: ($scope, $el, attrs) -> 
    $scope.$watch ( -> $el.attr("href") ), (href) ->
      ignore = attrs.plunkerRouteIgnore
      
      #console.log "Href", ignore, href, attrs
      
      if href.match(new RegExp(ignore))
        #console.log "Matched", attrs
        #$el.attr("target", "_self")
      else
        #$el.removeAttr("target")
]