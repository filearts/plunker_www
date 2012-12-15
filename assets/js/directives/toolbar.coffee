#= require ../services/visitor
#= require ../services/session
#= require ../services/downloader

module = angular.module "plunker.toolbar", [
  "plunker.visitor"
  "plunker.session"
  "plunker.downloader"
  "plunker.notifier"
]

module.directive "plunkerToolbar", ["$location", "session", "downloader", "notifier", ($location, session, downloader, notifier) ->
  restrict: "E"
  scope: {}
  replace: true
  template: """
    <div class="plunker-toolbar btn-toolbar">
      <div class="btn-group" ng-show="!session.plunk || session.plunk.isWritable()">
        <button ng-click="session.save()" title="Save your work as a new Plunk" class="btn btn-primary"><i class="icon-save"></i><span class="shrink"> Save</span></button>
      </div>
      <div class="btn-group" ng-show="session.isSaved()">
        <button ng-click="session.fork()" title="Save your changes as a fork of this Plunk" class="btn"><i class="icon-git-fork"></i><span class="shrink"> Fork</span></button>
        <button data-toggle="dropdown" class="btn dropdown-toggle"><span class="caret"></span></button>
        <ul class="dropdown-menu" ng-switch on="session.private">
          <li ng-switch-when="false"><a ng-click="session.fork({private: true})">Fork to private plunk</a></li>
          <li ng-switch-when="true"><a ng-click="session.fork({private: false})">Fork to public plunk</a></li>
        </ul>
      </div>
      <div ng-show="session.plunk.isWritable() && session.plunk.isSaved()" class="btn-group">
        <button ng-click="promptDestroy()" title="Delete the current plunk" class="btn btn-danger"><i class="icon-trash"></i></button>
      </div>
      <div class="btn-group"><a href="/edit/" title="Start a new plunk from a blank slate" class="btn btn-success"><i class="icon-file"></i><span class="shrink"> New</span></a>
        <button data-toggle="dropdown" class="btn btn-success dropdown-toggle"><span class="caret"></span></button>
        <ul class="dropdown-menu">
          <li><a href="/edit/gist:1986619">jQuery<a href="/edit/gist:1992850" class="coffee" title="In coffee-script"><img src="/img/coffeescript-logo-small_med.png"></a></a></li>
          <li><a href="/edit/gist:2006604">jQuery UI</a></li>
          <li class="divider"></li>
          <li class="dropdown-submenu">
            <a tabindex="-1" href="#">AngularJS</a>
            <ul class="dropdown-menu">
              <li><a href="/edit/gist:3510140">1.0.1<a href="/edit/gist:3189582" class="coffee" title="In coffee-script"><img src="/img/coffeescript-logo-small_med.png"></a></a></li>
              <li class="divider"></li>
              <li><a href="/edit/gist:3662656">1.0.2<a href="/edit/gist:3662659" class="coffee" title="In coffee-script"><img src="/img/coffeescript-logo-small_med.png"></a></a></li>
              <li><a href="/edit/gist:3743008">1.0.2 + Jasmine</a></li>
              <li class="divider"></li>
              <li><a href="/edit/gist:3662702">1.1.0 (unstable)<a href="/edit/gist:3662696" class="coffee" title="In coffee-script"><img src="/img/coffeescript-logo-small_med.png"></a></a></li>
            </ul>
          </li>
          <li class="divider"></li>
          <li><a href="/edit/gist:2016721">Bootstrap<a href="/edit/gist:2016721" class="coffee" title="In coffee-script"><img src="/img/coffeescript-logo-small_med.png"></a></a></li>
          <li class="divider"></li>
          <li><a href="/edit/gist:2050713">Backbone.js<a href="/edit/gist:2050746" class="coffee" title="In coffee-script"><img src="/img/coffeescript-logo-small_med.png"></a></a></li>
          <li class="divider"></li>
          <li><a href="/edit/gist:3510115">YUI</a></li>
          <li class="divider"></li>
          <li>
            <a href="javascript:void(0)" ng-click="promptImportGist()" title="Import code from a gist or another plunk">Import gist...</a>
          </li>
          <li class="divider"></li>
          <li>
            <div ng-click="builder.launch()" title="Launch the Plunk builder (coming soon...)"><i class="icon-beaker"></i>Launch builder...</div>
          </li>
        </ul>
      </div>
      <div class="btn-group">
        <button ng-click="triggerDownload()" class="btn" title="Save your work as a zip file">
          <i class="icon-download-alt" />
        </button>
      </div>
      <div class="btn-group" ng-show="session.isSaved()">
        <button ng-click="toggleFavorite()" class="btn" ng-class="{starred: session.plunk.thumbed, 'btn-inverse': session.plunk.thumbed}" title="Save this Plunk in your favorites">
          <i class="icon-star" />
        </button>
      </div>
    </div>
  """
  link: ($scope, el, attrs) ->
    $scope.session = session
    
    $scope.promptDestroy = ->
      notifier.confirm "Confirm Deletion", "Are you sure that you would like to delete this plunk?",
        confirm: -> session.destroy()          
    
    $scope.triggerDownload = ->
      downloader.download session.toJSON(), if session.plunk?.id then "plunk-#{session.plunk.id}.zip" else "plunk.zip"
]