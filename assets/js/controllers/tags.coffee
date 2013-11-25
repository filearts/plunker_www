#= require ./../services/menu
#= require ./../services/plunks

#= require ./../directives/timeago
#= require ./../directives/gallery


module = angular.module "plunker.tags", [
  "plunker.timeago"
  "plunker.menu"
  "plunker.gallery"
  "plunker.plunks"
]

module.factory "tags", ["$http", "url", ($http, url) ->
  $http.get("#{url.api}/tags").then (response) -> response.data
]

tagsTemplate = """
  <div class="container">
    <div class="row" ng-switch on="view">
      <div class="span3">
        <ul class="nav nav-list">
          <li class="nav-header">Popular tags</li>
          <li ng-repeat="tagInfo in tags">
            <span class="badge pull-right" ng-bind="tagInfo.count"></span>
            <a ng-href="tags/{{tagInfo.tag}}" ng-bind="tagInfo.tag">
            </a>
          </li>
        </ul>
      </div>
      <div class="span9" ng-switch-when="plunks">
        <h1>Viewing: {{taglist}}</h1>
        <plunker-gallery plunks="plunks"></plunker-gallery>

        <div class="row">
          <plunker-pager class="pull-right" collection="plunks"></plunker-pager>
        </div>
      </div>
      <div class="span9" ng-switch-default>
        <h1>Browse tags</h1>
        <p>
          Using the menu on the left, you can browse the top tags on Plunker.
          Click a tag to see the most popular plunks with that tag.
        </p>
        <p>
          Also note, that if you want to filter for plunks that have more than
          one tag, you can do so by changing the url to tag1,tag2,etc..
        </p>
      </div>
    </div>
  </div>
"""

module.config ["$routeProvider", ($routeProvider) ->
  $routeProvider.when "/tags",
    template: tagsTemplate

    controller: ["$rootScope", "$scope", "menu", "tags", ($rootScope, $scope, menu, tags) ->
      $scope.tags = tags
      $scope.view = "list"
      
      $rootScope.page_title = "Tags"          
      
      menu.activate "tags"
    ]
    
  $routeProvider.when "/tags/:taglist",
    template: tagsTemplate
    
    controller: ["$rootScope", "$scope", "$location", "$routeParams", "plunks", "url", "menu", "tags", ($rootScope, $scope, $location, $routeParams, plunks, url, menu, tags) ->
      defaultParams =
        pp: 12
        files: 'yes'
        
      $scope.tags = tags
      $scope.view = "plunks"
      $scope.taglist = $routeParams.taglist.split(",").join(", ")
      $scope.plunks = plunks.query(url: "#{url.api}/tags/#{$routeParams.taglist}", params: angular.extend(defaultParams, $location.search()))
      
      $rootScope.page_title = "Tags"          
      
      menu.activate "tags"
    ]
]

module.run ["menu", (menu) ->
  menu.addItem "tags",
    title: "Explore tags"
    href: "/tags"
    'class': "icon-tags"
    text: "Tags"
]
