# #= require ../../vendor/ui-bootstrap/


#= require ../services/catalogue
#= require ../services/visitor

module = angular.module "plunker.packages", [
  "plunker.catalogue"
  "plunker.visitor"
]


module.run ["$templateCache", ($templateCache) ->
  $templateCache.put "partials/packages.html", """
    <div class="container">
      <div class="row">
        <div class="span3">
          <label>Search:
            <input type="search" ng-model="search.$">
          </label>
          <ul class="nav nav-list">
            <li class="nav-header">Packages</li>
            <li ng-repeat="package in packages | filter:search" ng-class="{active: package==pkgDef}">
              <a ng-href="packages/{{package.name}}" ng-bind="package.name"></a>
            </li>
          </ul>
        </div>
        <div class="span9" ng-show="pkgDef">
          <h1 ng-bind="pkgDef.name"></h1>
          <p ng-bind="pkgDef.description"></p>
          <p>
            Latest version: <strong ng-bind="pkgDef.getLatestVersion().semver"></strong>
          </p>
          <p>
            <a class="btn btn-primary" ng-href="packages/{{pkgDef.name}}/edit">Edit</a>
        </div>
      </div>
    </div>
  """
]

module.config ["$routeProvider", ($routeProvider) ->
  $routeProvider.when "/packages/",
    templateUrl: "partials/packages.html"
    resolve:
      packages: ["$route", "catalogue", ($route, catalogue) ->
        catalogue.find().$$refreshing
      ]
      
    controller: ["$rootScope", "$scope", "$routeParams", "visitor", "packages", ($rootScope, $scope, $routeParams, visitor, packages) ->
      $rootScope.page_title = "Package repository"
      
      $scope.packages = packages
      $scope.visitor = visitor
    ]
]

module.config ["$routeProvider", ($routeProvider) ->
  $routeProvider.when "/packages/:package",
    templateUrl: "partials/packages.html"
    resolve:
      pkgDef: ["$route", "catalogue", ($route, catalogue) ->
        catalogue.findOrCreate(name: $route.current.params.package).refresh()
      ]
      
    controller: ["$rootScope", "$scope", "$routeParams", "visitor", "catalogue", "pkgDef", ($rootScope, $scope, $routeParams, visitor, catalogue, pkgDef) ->
      $rootScope.page_title = "Package repository"
      
      $scope.packages = catalogue.find()
      $scope.visitor = visitor
      $scope.pkgDef = pkgDef
    ]
]

module.run ["menu", (menu) ->
  menu.addItem "packages",
    title: "Explore packages"
    href: "/packages"
    'class': "icon-folder-close"
    text: "Packages"
]
