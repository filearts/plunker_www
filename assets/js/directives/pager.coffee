#= require ./../../vendor/URL/lib/URL


module = angular.module "plunker.pager", []

module.filter "relname", [ () ->
  (name) ->
    switch name
      when "first" then "&laquo;"
      when "prev" then "&lsaquo;"
      when "next" then "&rsaquo;"
      when "last" then "&raquo;"
      else name
]

module.filter "reltitle", [ () ->
  (name) ->
    switch name
      when "first" then "First page"
      when "prev" then "Previous page"
      when "next" then "Next page"
      when "last" then "Last page"
]

module.directive "plunkerPager", [ "$location", ($location) ->
  restrict: "E"
  replace: true
  scope:
    collection: "="
    path: "@"
  template: """
    <div class="plunker-pager pagination">
      <ul>
        <li ng-repeat="link in pages">
          <a ng-href="{{link.href}}" title="{{link.rel | reltitle}}" ng-bind-html-unsafe="link.rel | relname"></a>
        </li>
      </ul>
    </div>
  """
  link: ($scope, $el, attrs) ->
    appUrl = (url) ->
      current = URL.parse($location.absUrl())
      parsed = URL.parse(url).queryKey
      search = $location.search()
      
      current.path = attrs.path if attrs.path
      
      if parsed.p and parsed.p != search.p
        if parsed.p != "1" then current.queryKey.p = parsed.p
        else delete current.queryKey.p
      
      URL.make(current)

    
    $scope.$watch "collection.links()", (links) ->
      pages = []
      pages.push(rel: "first", href: appUrl(href)) if href = links.first
      pages.push(rel: "prev", href: appUrl(href)) if href = links.prev
      pages.push(rel: "next", href: appUrl(href)) if href = links.next
      pages.push(rel: "last", href: appUrl(href)) if href = links.last
      $scope.pages = pages
    , true

]