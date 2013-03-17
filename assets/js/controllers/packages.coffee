#= require ./../../vendor/typeahead/dist/typeahead

#= require ./../../vendor/ui-bootstrap/ui-bootstrap-tpls-0.2.0


#= require ./../services/catalogue
#= require ./../services/visitor
#= require ./../services/url

#= require ./../directives/eip


module = angular.module "plunker.packages", [
  "plunker.catalogue"
  "plunker.visitor"
  "plunker.eip"
  "plunker.url"
  "ui.bootstrap"
]

module.directive "plunkerTypeahead", [ "url", (url) ->
  restrict: "A"
  link: ($scope, $el, attrs) ->
    $($el).addClass("typeahead plunker-typeahead")
    $($el).typeahead
      name: "packages"
      prefetch: "#{url.api}/catalogue/typeahead"
]


module.run ["$templateCache", ($templateCache) ->
  $templateCache.put "partials/packages.html", """
    <div class="container">
      <div class="row">
        <div class="span12">
          <div class="package-search input-prepend input-append">
            <div class="add-on"><i class="icon-search"></i></div>
            <input type="text" plunker-typeahead placeholder="Seach packages" ng-model="search.term" />
            <button class="btn btn-large btn-success" ng-disabled="!search.term">Open</button>
          </div>
        </div>
        <div class="span3">
          <label>Search:
            <input type="search" ng-model="search.$">
          </label>
          <ul ng-show="false" class="nav nav-list">
            <li class="nav-header">Packages</li>
            <li ng-repeat="package in packages | filter:search | orderBy:'name'" ng-class="{active: package==pkgDef}">
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
          <p ng-show="pkgDef.getLatestVersion().dependencies.length">
            Dependencies:
            <ul class="list-unstyled">
              <li ng-repeat="dep in pkgDef.getLatestVersion().dependencies"><strong ng-bind="dep.name"></strong>: {{dep.semver}}</li>
            </ul>
          </p>
          <p ng-show="pkgDef.editable">
            <a class="btn btn-primary" ng-href="packages/{{pkgDef.name}}/edit">Edit</a>
            <a class="btn btn-danger" ng-click="promptDelete(pkgDef)">Delete</a>
          </p>
          <h4>Versions:</h4>
          <details ng-repeat="versionDef in pkgDef.versions">
            <summary>Version: <strong ng-bind="versionDef.semver"></strong></summary>
            <div ng-show="versionDef.dependencies.length">
              Dependencies:
              <ul class="list-unstyled">
                <li ng-repeat="dep in pkgDef.getLatestVersion().dependencies"><strong ng-bind="dep.name"></strong>: {{dep.semver}}</li>
              </ul>
            </div>
            <div ng-show="versionDef.scripts.length">
              Scripts:
              <ul>
                <li ng-repeat="url in versionDef.scripts"><code ng-bind="url"></code></li>
              </ul>
            </div>
            <div ng-show="versionDef.styles.length">
              Stylesheets:
              <ul>
                <li ng-repeat="url in versionDef.styles"><code ng-bind="url"></code></li>
              </ul>
            </div>
          </details>
        </div>
      </div>
    </div>
  """
  
  $templateCache.put "partials/edit_package.html", """
    <div class="container package-editor">
      <div class="row">
        <div class="span12"
          <input class="input-xxlarge" typeahead placeholder="Seach packages" />
        </div>
        <div class="span3">
          <label>Search:
            <input type="search" ng-model="search.$">
          </label>
          <ul class="nav nav-list">
            <li class="nav-header">Packages</li>
            <li ng-repeat="package in packages | filter:search | orderBy:'name'" ng-class="{active: package==pkgDef}">
              <a ng-href="packages/{{package.name}}" ng-bind="package.name"></a>
            </li>
          </ul>
        </div>
        <div class="span9" ng-show="pkgDef">
          <form name="packager" ng-submit="submit(pkgDef)">
            <fieldset>
              <legend>Edit package</legend>
              <label>Package name:</label>
              <input name="name" placeholder="Package name" ng-model="pkgDef.name" ng-required ng-pattern="/^[-._a-z0-9]+$/" />
              <label>Description:</label>
              <textarea name="description" rows="2" placeholder="Describe your package..." ng-model="pkgDef.description"></textarea>
              <label>Versions:</label>
              <ul>
                <li ng-repeat="verDef in pkgDef.versions" ng-click="editVersion(verDef)">
                  <strong>{{verDef.semver}}</strong>:
                  <ng-pluralize count="verDef.scripts.length" when="{'0':'', 'one': '1 script', 'other': '{} scripts'}"></ng-pluralize>,
                  <ng-pluralize count="verDef.styles.length" when="{'0':'', 'one': '1 stylesheet', 'other': '{} stylesheets'}"></ng-pluralize>
                  <ul class="ops">
                    <li><a ng-click="editVersion(verDef)"><i class="icon-edit"></i></a></li>
                    <li><a ng-click="removeVersion(verDef)"><i class="icon-trash"></i></a></li>
                  </ul>
                </li>
                <li class="add"><a ng-click="addVersion()">Add version...</a></li>
              </ul>
              <div class="form-actions">
                <button type="submit" class="btn btn-primary">Save</button>
                <button ng-click="close()" class="btn">Cancel</button>
              </div>
            </fieldset>
          </form>
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
      
      $scope.search = {}
      $scope.packages = packages
      $scope.visitor = visitor
    ]
]

module.config ["$routeProvider", ($routeProvider) ->
  $routeProvider.when "/packages/:package",
    templateUrl: "partials/packages.html"
    resolve:
      pkgDef: ["$route", "catalogue", ($route, catalogue) ->
        pkgDef = catalogue.findOrCreate(name: $route.current.params.package)
        pkgDef.refresh() unless pkgDef.$$refreshed_at or pkgDef.$$refreshing
        pkgDef.$$refreshing or pkgDef        
      ]
      
    controller: ["$rootScope", "$scope", "$routeParams", "visitor", "catalogue", "pkgDef", ($rootScope, $scope, $routeParams, visitor, catalogue, pkgDef) ->
      $rootScope.page_title = "Package repository"
      
      $scope.packages = catalogue.find()
      $scope.visitor = visitor
      $scope.pkgDef = pkgDef
    ]
]

module.service "versionEditor", [ "$dialog", ($dialog) ->
  edit: (version = {dependencies: [], scripts: [], styles: []}) ->
    dialog = $dialog.dialog
      template: """
        <form name="versioner" ng-submit="submit(version)">
          <div class="modal-header">
            <h4>Edit Version</h4>
          </div>
          <div class="modal-body">
            <label>Verion number:</label>
            <input name="semver" placeholder="0.0.0-0" ng-model="version.semver" ng-required />
            <label>Dependencies:</label>
            <ul>
              <li ng-repeat="(name, semver) in version.dependencies" plunker-eip eip-model="{name:name,semver:semver}" eip-destroy="version.dependencies.splice($index, 1)">
                <eip-show>
                  <strong ng-bind="eip.model.name"></strong>
                  @
                  <span ng-bind="eip.model.semver"></span>
                </eip-show>
                <eip-edit>
                  <input class="input-small" ng-model="eip.editing.name" placeholder="name">
                  @
                  <input class="input-small" ng-model="eip.editing.semver" placeholder="0.0.0-x">
                </eip-edit>
              </li>
              <li class="hide-edit add" plunker-eip eip-save="version.dependencies[newdep.name] = newdep.semver; newdep={}" eip-cancel="newdep={}" eip-model="newdep">
                <eip-show>
                  <a ng-click="eip.edit()">
                    Add dependency...
                  </a>
                </eip-show>
                <eip-edit>
                  <input class="input-small" ng-model="eip.editing.name" placeholder="name" />
                  @
                  <input class="input-small" ng-model="eip.editing.semver" placeholder="0.0.0-x" />
                </eip-edit>
              </li>
            </ul>            
            <label>Scripts:</label>
            <ul>
              <li ng-repeat="script in version.scripts" plunker-eip eip-model="script" eip-destroy="version.scripts.splice($index, 1)">
                <eip-show>
                  <code ng-bind="eip.model"></code>
                </eip-show>
                <eip-edit>
                  <input class="input-xlarge" ng-model="eip.editing" placeholder="http://source.of/javascript.js">
                </eip-edit>
              </li>
              <li class="hide-edit add" plunker-eip eip-save="version.scripts.push(newscript); newscript={}" eip-cancel="newscript={}" eip-model="newscript">
                <eip-show>
                  <a ng-click="eip.edit()">
                    Add source...
                  </a>
                </eip-show>
                <eip-edit>
                  <input class="input-xlarge" ng-model="eip.editing.url" placeholder="http://source.of/javascript.js">
                </eip-edit>
              </li>
            </ul>            
            <label>Stylesheets:</label>
            <ul>
              <li ng-repeat="style in version.styles" plunker-eip eip-model="style" eip-destroy="version.styles.splice($index, 1)">
                <eip-show>
                  <code ng-bind="eip.model"></code>
                </eip-show>
                <eip-edit>
                  <input class="input-xlarge" ng-model="eip.editing" placeholder="http://source.of/javascript.js">
                </eip-edit>
              </li>
              <li class="hide-edit add" plunker-eip eip-save="version.styles.push(newstyle); newstyle={}" eip-cancel="newstyle={}" eip-model="newstyle">
                <eip-show>
                  <a ng-click="eip.edit()">
                    Add source...
                  </a>
                </eip-show>
                <eip-edit>
                  <input class="input-xlarge" ng-model="eip.editing.url" placeholder="http://source.of/stylesheet.css">
                </eip-edit>
              </li>
            </ul>            
          </div>
          <div class="modal-footer">
            <button type="submit" class="btn btn-primary">Save</button>
            <button type="button" ng-click="cancel()" class="btn">Cancel</button>
          </div>
        </form>
      """
      controller: ["$scope", "dialog", ($scope, dialog) ->
        $scope.version = version
        $scope.newdep =
          name: ""
          semver: ""
        $scope.submit = (version) ->
          if $scope.versioner.$valid then dialog.close(version)
          else alert "Invalid package"
        $scope.cancel = -> dialog.close()
      ]
  
    dialog.open()
]

module.config ["$routeProvider", ($routeProvider) ->
  $routeProvider.when "/packages/:package/edit",
    templateUrl: "partials/edit_package.html"
    resolve:
      pkgDef: ["$route", "catalogue", ($route, catalogue) ->
        pkgDef = catalogue.findOrCreate(name: $route.current.params.package)
        pkgDef.refresh() unless pkgDef.$$refreshed_at or pkgDef.$$refreshing
        pkgDef.$$refreshing or pkgDef        
      ]
      
    controller: ["$rootScope", "$scope", "$routeParams", "visitor", "catalogue", "pkgDef", "versionEditor", ($rootScope, $scope, $routeParams, visitor, catalogue, pkgDef, versionEditor) ->
      $rootScope.page_title = "Package repository"
      
      $scope.packages = catalogue.find()
      $scope.visitor = visitor
      $scope.pkgDef = pkgDef
      
      $scope.addVersion = -> versionEditor.edit().then (verDef) ->
        console.log "$scope.package", $scope.package
        $scope.pkgDef.versions.push(verDef) if verDef
        console.log "Package returned", verDef
      $scope.editVersion = (verDef) -> versionEditor.edit(verDef)
    ]
]
module.run ["menu", (menu) ->
  menu.addItem "packages",
    title: "Explore packages"
    href: "/packages"
    'class': "icon-folder-close"
    text: "Packages"
]
