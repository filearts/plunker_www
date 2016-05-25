#= require script/dist/script

#= require ./../services/menu
#= require ./../services/plunks
#= require ./../services/url

#= require ./../directives/addthis
#= require ./../directives/gallery
#= require ./../directives/overlay
#= require ./../directives/pager


module = angular.module "plunker.explore", [
  "plunker.addthis"
  "plunker.gallery"
  "plunker.pager"
  "plunker.overlay"
  "plunker.menu"
  "plunker.plunks"
  "plunker.url"
]

filters =
  trending:
    href: "/plunks/trending"
    text: "Trending"
    order: "a"
  views:
    href: "/plunks/views"
    text: "Most viewed"
    order: "b"
  popular:
    href: "/plunks/popular"
    text: "Most starred"
    order: "c"
  recent:
    href: "/plunks/recent"
    text: "Recent"
    order: "d"

defaultParams =
  pp: 12
  files: 'yes'

resolvers =
  trending: ["$location", "url", "plunks", ($location, url, plunks) ->
    plunks.query(url: "#{url.api}/plunks/trending", params: angular.extend(defaultParams, $location.search())).$$refreshing
  ]
  views: ["$location", "url", "plunks", ($location, url, plunks) ->
    plunks.query(url: "#{url.api}/plunks/views", params: angular.extend(defaultParams, $location.search())).$$refreshing
  ]
  popular: ["$location", "url", "plunks", ($location, url, plunks) ->
    plunks.query(url: "#{url.api}/plunks/popular", params: angular.extend(defaultParams, $location.search())).$$refreshing
  ]
  recent: ["$location", "url", "plunks", ($location, url, plunks) ->
    plunks.query(url: "#{url.api}/plunks", params: angular.extend(defaultParams, $location.search())).$$refreshing
  ]

generateRouteHandler = (filter, options = {}) ->
  angular.extend
    templateUrl: "partials/explore.html"
    resolve:
      filtered: resolvers[filter]
    reloadOnSearch: true
    controller: ["$rootScope", "$scope", "$injector", "menu", "filtered", ($rootScope, $scope, $injector, menu, filtered) ->
      $rootScope.page_title = "Explore"
      
      $scope.plunks = filtered
      $scope.filters = filters
      $scope.activeFilter = filters[filter]
      
      menu.activate "plunks" unless options.skipActivate
      
      $injector.invoke(options.initialize) if options.initialize
    ]
  , options

module.config ["$routeProvider", ($routeProvider) ->
  initialLoad = [ "url", (url) -> $script(url.carbonadsH) if url.carbonadsH ]
  
  $routeProvider.when "/", generateRouteHandler("trending", {templateUrl: "partials/landing.html", skipActivate: true, initialize: initialLoad})
  $routeProvider.when "/plunks", generateRouteHandler("trending")
  $routeProvider.when "/plunks/#{view}", generateRouteHandler(view) for view, viewDef of filters
]

module.run ["menu", (menu) ->
  menu.addItem "plunks",
    title: "Explore plunks"
    href: "/plunks"
    'class': "icon-th"
    text: "Plunks"
]

module.run ["$templateCache", ($templateCache) ->
  $templateCache.put "partials/explore.html", """
    <div class="container">
      <plunker-pager class="pull-right" collection="plunks"></plunker-pager>
      
      <ul class="nav nav-pills pull-left">
        <li ng-repeat="(name, filter) in filters | orderBy:'order'" ng-class="{active: filter == activeFilter}">
          <a ng-href="{{filter.href}}" ng-bind="filter.text"></a>
        </li>
      </ul>
    
      <div class="row">
        <div class="span12">
          <plunker-gallery plunks="plunks"></plunker-gallery>
        </div>
      </div>
    
      <plunker-pager class="pagination-right" collection="plunks"></plunker-pager>
    </div>
  """
  
  $templateCache.put "partials/landing.html", """
    <div class="container plunker-landing">
      <div class="hero-unit">
        <h1>
          Plunker
          <small>Helping developers make the web</small>  
        </h1>
        <p class="description">
          Plunker is an online community for creating, collaborating on and sharing your web development ideas.
        </p>
        <p class="actions">
          <a href="/edit/" class="btn btn-primary">
            <i class="icon-edit"></i>
            Launch the Editor
          </a>
          <a href="/plunks" class="btn btn-success">
            <i class="icon-th"></i>
            Browse Plunks
          </a>
          <span class="addthis_default_style addthis_20x20_style" addthis-toolbox addthis-description="Plunker is an online community for creating, collaborating on and sharing your web development ideas.">
            <a target="_self" class="addthis_button_twitter"></a>
            <a target="_self" class="addthis_button_facebook"></a>
            <a target="_self" class="addthis_button_google_plusone_share"></a>
            <a target="_self" class="addthis_button_linkedin"></a>
            <a target="_self" class="addthis_button_compact"></a>
          </span>
        </p>
      </div>
      <div class="row">
        <div class="span4">
          <h4>Design goals</h4>
          <ul>
            <li><strong>Speed</strong>: Despite its complexity, the Plunker editor is designed to load in under 2 seconds.</li>
            <li><strong>Ease of use</strong>: Plunker's features should just work and not require additional explanation.</li>
            <li><strong>Collaboration</strong>: From real-time collaboration to forking and commenting, Plunker seeks to encourage users to work together on their code.</li>
          </ul>
        </div>
        <div class="span4">
          <h4>Advertisement</h4>
          <div id="carbonads-container">
            <div class="carbonad">
              <div id="azcarbon"></div>
            </div>
          </div>
          <a target="_blank" href="https://carbonads.net/dev_code.php">Advertise here</a>
        </div>
        <div class="span4">
          <h4>Features</h4>
          <ul>
            <li>Real-time code collaboration</li>
            <li>Fully-featured, customizable syntax editor</li>
            <li>Live previewing of code changes</li>
            <li>As-you-type code linting</li>
            <li>Forking, commenting and sharing of Plunks</li>
            <li>Fully open-source on GitHub under the MIT license</li>
            <li>And many more to come...</li>
          </ul>
        </div>

    
      </div>
      
      <div class="page-header">
        <h1>See what users have been creating</h1>
      </div>
      
      <plunker-pager class="pull-right" path="/plunks/" collection="plunks"></plunker-pager>
      
      <ul class="nav nav-pills pull-left">
        <li ng-repeat="(name, filter) in filters | orderBy:'order'" ng-class="{active: filter == activeFilter}">
          <a ng-href="{{filter.href}}" ng-bind="filter.text"></a>
        </li>
      </ul>
    
      <div class="row">
        <div class="span12">
          <plunker-gallery plunks="plunks"></plunker-gallery>
        </div>
      </div>
    
      <plunker-pager class="pagination-right" path="/plunks/" collection="plunks"></plunker-pager>
    </div>
  """
]
