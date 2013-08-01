#= require ./../services/panes
#= require ./../services/url
#= require ./../services/catalogue
#= require ./../services/notifier
#= require ./../services/updater
#= require ./../services/session

#= require ./../directives/pager


module = angular.module("plunker.panes")

module.requires.push "plunker.url"
module.requires.push "plunker.catalogue"
module.requires.push "plunker.notifier"
module.requires.push "plunker.pager"
module.requires.push "plunker.updater"
module.requires.push "plunker.session"


module.run [ "$q", "$timeout", "panes", "url", "updater", "session", "catalogue", ($q, $timeout, panes, url, updater, session, catalogue) ->

  panes.add
    id: "catalogue"
    icon: "book"
    size: "50%"
    order: 300
    title: "Find and external libraries"
    description: """
      Find external libraries and add them to your plunk.
    """
    template: """
      <plunker-catalogue></plunker-catalogue>
    """
    
    link: ($scope, $el, attrs) ->
      
      $scope.$watch "pane.active", (active) ->
        $scope.popular ||= catalogue.findAll() if active
      
      $scope.$watch ( -> session.getActiveBuffer()), (buffer) ->
        delete $scope.markup
        delete $scope.updater
        delete $scope.clean
        
        if buffer.filename.match(/\.html$/)
        
          $scope.clean = buffer.content
          $scope.updater = true
          $scope.markup = updater.parse(buffer.content)
          $scope.markup.findAllDependencies()
          
      $scope.$watch ( -> session.getActiveBuffer().content), (content) ->
        $scope.dirty = $scope.clean != content
      
      
      recheck = ->
        if $scope.updater and $scope.dirty
          $scope.markup = updater.parse($scope.clean = session.getActiveBuffer().content)
          $scope.markup.findAllDependencies()
          $scope.dirty = false
      
      setInterval ->
        $scope.$apply(recheck)
      , 2000
      
      recheck()
          
]
module.directive "plunkerPackageBlock", [ () ->
  restrict: "E"
  replace: true
  scope:
    'package': "="
    click: "&"
    insert: "&"
  template: """
    <div class="plunker-package-block">
      <div class="package-header">
        <h4>
          <ul class="package-meta inline pull-right">
            <li><i class="icon-download"></i><span ng-bind="package.bumps | shorten"></span></li>
          </ul>
          <a ng-click="click(package)" ng-bind="package.name"></a>
          
          <button class="btn btn-mini" ng-click="insert(package)" tooltip="Add the selected package and its dependencies to your active plunk">
            <i class="icon-magic"></i>
          </button>

          <ul class="package-versions inline">
            <li ng-repeat="version in package.versions | orderBy:'-semver' | limitTo:3">
              <a class="label" ng-class="{'label-warning': version.unstable}" ng-click="click({package: package, version: version})" ng-bind="version.semver"></a>
            </li>
            <li class="dropdown" ng-show="package.versions.length > 3">
              <a class="more dropdown-toggle">More...</a>
              <ul class="dropdown-menu">
                <li ng-repeat="version in package.versions | orderBy:'-semver' | limitTo:3 - package.versions.length">
                  <a ng-click="click({package: package, version: version})" ng-bind="version.semver"></a>
                </li>
              </ul>
            </li>
          </ul>
        </h4>
      </div>
      <p class="package-description" ng-bind="package.description"></p>

    </div>
  """
  link: ($scope, $el, attrs) ->
    
]

module.filter "shorten", ->
  (val) ->
    val = parseInt(val, 10)
    
    if val >= 10000 then Math.round(val / 1000) + "k"
    else if val >= 1000 then Math.round(val / 100) / 10 + "k"
    else val

module.controller "plunkerCatalogueController", [ "$scope", "catalogue", "session", "visitor", ($scope, catalogue, session, visitor) ->
  $scope.state = state = @
  $scope.visitor = visitor
  
  
  $scope.moveTo = state.moveTo = (view) ->
    state.view = view
    
  $scope.goHome = state.goHome = ->
    $scope.moveTo("popular")
    $scope.popular.refresh()
    $scope.query = ""
    
  $scope.openPackages = state.openPackages = ->
    $scope.moveTo("dependencies")
    $scope.query = ""
    
  $scope.refreshDependencies = state.updateDependencies = ->
    $scope.markup.parse($scope.clean = session.getActiveBuffer().content) if $scope.markup
    $scope.markup.findAllDependencies()
    $scope.moveTo("dependencies")
    $scope.query = ""
    
  $scope.updateInclude = state.updateInclude = (entry, verDef) ->
    $scope.markup.updateEntry(child) for child in entry.children
    $scope.markup.updateEntry(entry, verDef)
    $scope.markup.parse($scope.clean = session.activeBuffer.content = $scope.markup.toHtml())
    $scope.markup.findAllDependencies()
  
  $scope.updateAll = state.updateAll = ->
    $scope.markup.updateEntry(entry) for entry in $scope.markup.obsolete
    $scope.markup.parse($scope.clean = session.activeBuffer.content = $scope.markup.toHtml())
    $scope.markup.findAllDependencies()
  
  $scope.insertPackage = state.insertPackage = (pkg, verDef) ->
    semver = verDef?.semver or "*"
    
    required = "#{pkg.name}@#{semver}"
    
    pkg.bump()
    
    $scope.markup.addRequired(required).then($scope.updateInclude)
  
  $scope.search = state.search = ->
    $scope.moveTo("search")
    $scope.query = $scope.searchTerm
    $scope.results = catalogue.search($scope.query)
  
  $scope.createPackage = state.createPackage = ->
    $scope.moveTo("package.edit")
    $scope.package = null
  
  $scope.createPackageVersion = state.createPackageVersion = (pkg) ->
    $scope.moveTo("package.version.edit")
    $scope.package = pkg
    $scope.currentVersion = null
    
  $scope.editPackage = state.editPackage = (pkg) ->
    $scope.moveTo("package.edit")
    $scope.package = pkg
  
  $scope.destroyPackage = state.destroyPackage = (pkg) ->
    pkg.destroy().then ->
      state.goHome()
  
  $scope.editPackageVersion = state.editPackageVersion = (pkg, version) ->
    $scope.moveTo("package.version.edit")
    $scope.package = pkg
    $scope.currentVersion = version or pkg.getMatchingVersion()
  
  $scope.destroyPackageVersion = state.destroyPackageVersion = (pkg, version) ->
    pkg.destroyVersion(version).then (pkg) ->
      state.editPackage(pkg)
    
  $scope.openVersion = state.openVersion = (pkg, version) ->
    $scope.moveTo("package.version")
    $scope.package = pkg
    $scope.currentVersion = version or pkg.getMatchingVersion()
    
  $scope.moveTo("popular")
]

module.directive "plunkerCatalogue", [ () ->
  restrict: "E"
  replace: true
  controller: "plunkerCatalogueController"
  template: """
    <div class="plunker-catalogue">
      <form class="plunker-searchbar" ng-class="{markup: updater}" ng-submit="search()">
        <div ng-show="updater" class="pull-right">
          <a ng-hide="dirty" class="label updates" ng-class="{'label-important': markup.obsolete.length}" ng-click="openPackages()" ng-bind="markup.dependencies.length | number"></a>
          <a ng-show="dirty" class="label updates" ng-click="refreshDependencies()"><i class="icon-refresh"></i></a>
        </div>
        <a class="btn pull-left" ng-click="goHome()"><i class="icon-home"></i></a>
        <div class="plunker-searchbox input-append">
          <div class="input-wrapper">
            <input class="" type="text" ng-model="searchTerm" placeholder="Search packages..." />
          </div>
          <button class="btn"><i class="icon-search"></i></button>
        </div>
      </form>
      <div ng-switch on="state.view">
        <div ng-switch-when="dependencies">
          <div class="sub-header">
            <small class="pull-right"><a ng-show="markup.obsolete.length" ng-click="updateAll()">
              <i class="icon-refresh"></i>
              Update all
            </a></small>
            <h3>Packages in the current file</h3>
          </div>
          <section ng-show="markup.obsolete.length">
            <h4>Out of date</h4>
            <ul>
              <li class="entry" ng-repeat="entry in markup.obsolete">
                <strong ng-bind="entry.ref.name"></strong>
                <span ng-show="entry.currentVer" ng-bind-template="@{{entry.currentVer}} is out of date"></span>
                <span ng-hide="entry.currentVer"> is required, but not included</span>
                <div class="pull-right btn-group">
                  <button ng-click="updateInclude(entry)" class="btn btn-success btn-small">
                    <i class="icon-refresh"></i> Update to {{entry.ref.ver.semver}}
                  </button>
                  <button class="btn btn-success btn-small dropdown-toggle" data-toggle="dropdown">
                    <span class="caret"></span>
                  </button>
                  <ul class="dropdown-menu">
                    <li ng-repeat="verDef in entry.ref.pkg.getMatchingVersions(entry.ref.range)">
                      <a ng-click="updateInclude(entry, verDef)">Update to {{verDef.semver}}</a>
                    </li>
                  </ul>
                </div>
              </li>
            </ul>
          </section>
          <section ng-show="markup.current.length">
            <h4>Up to date</h4>
            <ul>
              <li class="entry" ng-repeat="entry in markup.current">
                <strong ng-bind="entry.ref.name"></strong>
                <span ng-bind-template="@{{entry.currentVer}} is up to date"></span>
                <div class="pull-right btn-group">
                  <button ng-click="updateInclude(entry)" class="btn btn-small">
                    <i class="icon-refresh"></i> Update to {{entry.ref.ver.semver}}
                  </button>
                  <button class="btn btn-small dropdown-toggle" data-toggle="dropdown">
                    <span class="caret"></span>
                  </button>
                  <ul class="dropdown-menu">
                    <li ng-repeat="verDef in entry.ref.pkg.getMatchingVersions(entry.ref.range)">
                      <a ng-click="updateInclude(entry, verDef)">Update to {{verDef.semver}}</a>
                    </li>
                  </ul>
                </div>
              </li>
            </ul>
          </section>
        </div>
        <div ng-switch-when="popular">
          <div class="sub-header">
            <h3>
              <small ng-show="visitor.user.login" class="pull-right"><a ng-click="createPackage()">Add new...</a></small>
              Popular packages
            </h3>
          </div>
          <plunker-package-block insert="insertPackage(package)" click="openVersion(package, version)" package="package" ng-repeat="package in popular"></plunker-package-block>
          <plunker-pager nolink="true" collection="popular" nav="popular.refresh(url)"></plunker-pager>
        </div>
        <div ng-switch-when="search">
          <div class="sub-header">
            <h3>
              <small ng-show="visitor.user.login" class="pull-right"><a ng-click="createPackage()">Add new...</a></small>
              Search results: <span ng-bind="query"></span>
            </h3>
          </div>
          <plunker-package-block insert="insertPackage(package)" click="openVersion(package, version)" package="package" ng-repeat="package in results"></plunker-package-block>
          <p ng-hide="!results || results.length">No results found for {{query}}.</p>
          <p ng-hide="results && !results.loading">Searching for {{query}}.</p>
        </div>
        <div ng-switch-when="package.version">
          <div class="sub-header">
            <div class="package-version-toggle dropdown pull-right">
              <div class="dropdown-toggle"><span ng-bind="currentVersion.semver"></span><span ng-show="currentVersion.unstable"> (unstable)</span><span class="caret"></span></div>
              <ul class="dropdown-menu">
                <li ng-class="{active: version == currentVersion}" ng-repeat="version in package.versions">
                  <a ng-click="openVersion(package, version)" ng-bind="version.semver + (version.unstable && ' (unstable)' || '')"></a>
                </li>
              </ul>
            </div>
            <h3>{{prefix}}<a ng-click="openVersion(package, version)" ng-bind="package.name"></a></h3>
          </div>
          <p ng-bind="package.description"></p>
          <ul class="package-meta inline">
            <li ng-show="package.homepage"><i class="icon-link"></i><a ng-href="{{package.homepage}}">Website</a></li>
            <li ng-show="package.documentation"><i class="icon-info-sign"></i><a ng-href="{{package.documentation}}">Docs</a></li>
          </ul>
          <details class="package-scripts" ng-show="currentVersion.scripts.length">
            <summary>Scripts <span ng-bind-template="({{currentVersion.scripts.length}})"></span></summary>
            <ol>
              <li ng-repeat="url in currentVersion.scripts"><code ng-bind="url"></code></li>
            </ol>
          </details>
          <details class="package-scripts" ng-show="currentVersion.styles.length">
            <summary>Stylesheets <span ng-bind-template="({{currentVersion.styles.length}})"></span></summary>
            <ol>
              <li ng-repeat="url in currentVersion.styles"><code ng-bind="url"></code></li>
            </ol>
          </details>
          <details class="package-scripts" ng-show="currentVersion.dependencies.length">
            <summary>Dependencies <span ng-bind-template="({{currentVersion.dependencies.length}})"></span></summary>
            <ol>
              <li ng-repeat="dependency in currentVersion.dependencies"><strong ng-bind="dependency.name"></strong> - <code ng-bind="dependency.range"></code></li>
            </ol>
          </details>
          <ul class="package-ops inline pull-right">
            <li ng-show="updater">
              <button class="btn btn-small" ng-click="insertPackage(package, currentVersion)" tooltip="Add the selected package and its dependencies to your active plunk">
                <i class="icon-magic"></i>
                Add
              </button>
            </li>
            <li ng-show="package.maintainer">
              <button class="btn btn-small btn-primary" ng-click="editPackage(package)" tooltip="Edit this package">
                <i class="icon-pencil"></i>
                Edit
              </button>
            </li>
          </ul>
        </div>
        <div ng-switch-when="package.edit">
          <div class="sub-header">
            <h3>{{package.name && "Edit: " || "Create package" }}<a ng-click="openVersion(package, currentVersion)" ng-bind="package.name"></a></h3>
          </div>
          <package-editor package="package"></package-editor>
        </div>
        <div ng-switch-when="package.version.edit">
          <div class="sub-header">
            <h3><a ng-click="openVersion(package, currentVersion)" ng-bind="package.name"></a> - {{currentVersion.semver || "Create version:" }}</h3>
          </div>
          <version-editor package="package" version="currentVersion"></version-editor>
        </div>
      </div>
    </div>
  """
]



module.directive "packageEditor", [ "catalogue", "notifier", (catalogue, notifier) ->
  restrict: "E"
  replace: true
  require: "^plunkerCatalogue"
  scope:
    'package': "="
  template: """
    <form class="package-editor" ng-submit="save()">
      <label>Package name:
        <input ng-disabled="package.name" ng-model="editing.name" placeholder="package_name" required>
      </label>
      <label>Description:
        <textarea ng-model="editing.description" placeholder="Package description..."></textarea>
      </label>
      <label>Website:
        <input ng-model="editing.homepage" placeholder="http://homepage">
      </label>
      <label>Documentation:
        <input ng-model="editing.documentation" placeholder="http://documentation">
      </label>
      <div ng-show="package.name">
        <label>Versions:</label>
        <ul class="" ng-show="package.name">
          <li ng-repeat="version in editing.versions">
            <a ng-click="controller.editPackageVersion(package, version)" ng-bind="version.semver"></a>
          </li>
          <li class="add-new">
            <a ng-click="controller.createPackageVersion(package)">Add new...</a>
          </li>
        </ul>
      </div>
      <ul class="package-ops inline pull-right">
        <li>
          <button class="btn btn-primary">Save</button>
        </li>
        <li>
          <button class="btn" type="button" ng-click="cancel()">Cancel</button>
        </li>
        <li ng-show="package.name">
          <button class="btn btn-danger" type="button" ng-click="destroy()">Delete</button>
        </li>
      </ul>
    </form>
  """
  link: ($scope, $el, attrs, controller) ->
    $scope.controller = controller
    
    delete $scope.package?.$$v
    $scope.editing = angular.copy($scope.package or {})
    
    $scope.save = ->
      if $scope.package then $scope.package.save($scope.editing).then (pkg) ->
        controller.openVersion(pkg)
      else catalogue.create($scope.editing).then (pkg) ->
        controller.createPackageVersion(pkg)
    
    $scope.cancel = ->
      if $scope.package then controller.openVersion($scope.package)
      else controller.goHome()
      
    $scope.destroy = ->
      if $scope.package then notifier.confirm "Are you sure you would like to delete this package?",
        confirm: -> controller.destroyPackage($scope.package).then (pkg) ->
          controller.goHome()
]


module.directive "versionEditor", [ "catalogue", (catalogue) ->
  restrict: "E"
  replace: true
  require: "^plunkerCatalogue"
  scope:
    version: "="
    'package': "="
  template: """
    <form name="versionEditor" class="version-editor" ng-submit="save()">
      <label>Semver:
        <input class="input-small" ng-disabled="version.semver" ng-model="editing.semver" placeholder="0.0.1" semver required>
        <label class="inline-checkbox">
          <input type="checkbox" ng-model="editing.unstable">
          Unstable
        </label>
      </label>
      <label>Scripts:</label>
      <ul class="editable-listing">
        <li ng-repeat="url in editing.scripts">
          <ul class="inline pull-right">
            <li><a ng-click="moveUp(editing.scripts, $index)"><i class="icon-arrow-up"></i></a></li>
            <li><a ng-click="moveDown(editing.scripts, $index)"><i class="icon-arrow-down"></i></a></li>
            <li><a ng-click="remove('script', editing.scripts, $index)"><i class="icon-trash"></i></a></li>
          </ul>
          <a class="existing-element" ng-click="editUrl('script', editing.scripts, $index)" ng-bind="url"></a>
        </li>
        <li class="add-new">
          <a ng-click="addNewElement('script', editing.scripts)">Add new...</a>
        </li>
      </ul>
      <label>Styles:</label>
      <ul class="editable-listing">
        <li ng-repeat="url in editing.styles">
          <ul class="inline pull-right">
            <li><a ng-click="moveUp(editing.styles, $index)"><i class="icon-arrow-up"></i></a></li>
            <li><a ng-click="moveDown(editing.styles, $index)"><i class="icon-arrow-down"></i></a></li>
            <li><a ng-click="remove('script', editing.styles, $index)"><i class="icon-trash"></i></a></li>
          </ul>
          <a class="existing-element" ng-click="editUrl('script', editing.styles, $index)" ng-bind="url"></a>
        </li>
        <li class="add-new">
          <a class="add-new" ng-click="addNewElement('script', editing.styles)">Add new...</a>
        </li>
      </ul>
      <label>Dependencies:</label>
      <ul class="editable-listing">
        <li ng-repeat="dep in editing.dependencies">
          <ul class="inline pull-right">
            <li><a ng-disabled="$first" ng-click="moveUp(editing.dependencies, $index)"><i class="icon-arrow-up"></i></a></li>
            <li><a ng-disabled="$last" ng-click="moveDown(editing.dependencies, $index)"><i class="icon-arrow-down"></i></a></li>
            <li><a ng-click="remove('dependency', editing.dependencies, $index)"><i class="icon-trash"></i></a></li>
          </ul>
          <a class="existing-element" ng-click="editDependency('dependency', editing.dependencies, $index)" ng-bind-template="{{dep.name}} @ {{dep.range}}"></a>
        </li>
        <li class="add-new">
          <a ng-click="addDependency()">Add new...</a>
        </li>
      </ul>
      <ul class="package-ops inline pull-right">
        <li>
          <button class="btn btn-primary">Save</button>
        </li>
        <li>
          <button class="btn" type="button" ng-click="cancel()">Cancel</button>
        </li>
        <li ng-show="package.name">
          <button class="btn btn-danger" type="button" ng-click="destroy()">Delete</button>
        </li>
      </ul>
    </form>
  """
  link: ($scope, $el, attrs, controller) ->
    $scope.controller = controller
    
    delete $scope.version?.$$v
    $scope.editing = angular.copy($scope.version) or
      scripts: []
      styles: []
      dependencies: []
    
    $scope.editUrl = (type, list, index) ->
      value = prompt("Enter the updated #{type}:", list[index])
      
      if value then list[index] = value
    
    $scope.addNewElement = (type, list) ->
      value = prompt("Enter the new #{type}:")
      if value then list.push(value)
      
    $scope.addDependency = () ->
      value = prompt("Enter the new dependency (as package@semver-range):")
      if value
        [name, range] = value.split("@").concat(["*"])
        $scope.editing.dependencies.push({name, range})
      
    $scope.moveUp = (list, index) ->
      if index
        prev = index - 1
        [list[prev], list[index]] = [list[index], list[prev]]
      
    $scope.moveDown = (list, index) ->
      if index < list.length - 1
        next = index + 1
        [list[next], list[index]] = [list[index], list[next]]
    
    $scope.remove = (type, list, index) ->
      if confirm("Are you sure that you would like to remove the #{type} #{list[index]}?")
        list.splice(index, 1)
    
    $scope.save = ->
      if $scope.version then $scope.package.updateVersion($scope.editing).then (pkg) ->
        controller.openVersion(pkg, $scope.editing)
        return
      else $scope.package.addVersion($scope.editing).then (pkg) ->
        controller.openVersion(pkg, $scope.editing)
        return
      
    $scope.cancel = ->
      controller.editPackageVersion($scope.package, $scope.version)
    
    $scope.destroy = ->
      controller.destroyPackageVersion($scope.package, $scope.version).then (pkg) ->
        controller.openVersion(pkg)
]