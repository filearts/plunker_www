#= require ./../../vendor/ui-bootstrap/ui-bootstrap-tpls-0.3.0

#= require ./../services/visitor
#= require ./../services/session
#= require ./../services/downloader
#= require ./../services/panes
#= require ./../services/url

module = angular.module "plunker.toolbar", [
  "plunker.visitor"
  "plunker.session"
  "plunker.downloader"
  "plunker.notifier"
  "plunker.panes"
  "plunker.url"
  "ui.bootstrap"
]

module.directive "plunkerToolbar", ["$location", "session", "downloader", "notifier", "panes", "visitor", "url", ($location, session, downloader, notifier, panes, visitor, url) ->
  restrict: "E"
  scope: {}
  replace: true
  template: """
    <div class="plunker-toolbar btn-toolbar">
      <div class="btn-group" ng-show="!session.plunk || session.plunk.isWritable()">
        <button ng-disabled="!session.isPlunkDirty()" ng-click="session.save()" class="btn btn-primary" tooltip-placement="bottom" tooltip="Save your work as a new Plunk">
          <i class="icon-save"></i><span class="shrink"> Save</span>
        </button>
      </div>
      <div class="btn-group" ng-show="session.isSaved()">
        <button ng-click="session.fork()" class="btn" tooltip-placement="bottom" tooltip="Save your changes as a fork of this Plunk">
          <i class="icon-git-fork"></i><span class="shrink"> Fork</span>
        </button>
        <button data-toggle="dropdown" class="btn dropdown-toggle" tooltip-placement="bottom" tooltip="Fork and toggle the privacy of this Plunk"><span class="caret"></span></button>
        <ul class="dropdown-menu" ng-switch on="session.private">
          <li ng-switch-when="false"><a ng-click="session.fork({private: true})">Fork to private plunk</a></li>
          <li ng-switch-when="true"><a ng-click="session.fork({private: false})">Fork to public plunk</a></li>
        </ul>
      </div>
      <div ng-show="session.plunk.isWritable() && session.plunk.isSaved()" class="btn-group">
        <button ng-click="promptDestroy()" class="btn btn-danger" tooltip-placement="bottom" tooltip="Delete the current plunk">
          <i class="icon-trash"></i>
        </button>
      </div>
      <div class="btn-group">
        <button ng-click="promptReset()" class="btn btn-success" tooltip-placement="bottom" tooltip="Create a new Plunk">
          <i class="icon-file"></i><span class="shrink"> New</span>
        </button>
        <button data-toggle="dropdown" class="btn btn-success dropdown-toggle" tooltip-placement="bottom" tooltip="Create a new Plunk from a template"><span class="caret"></span></button>
        <ul class="dropdown-menu">
          <li><a href="/edit/gist:1986619">jQuery<a href="/edit/gist:1992850" class="coffee" title="In coffee-script"><img src="/img/coffeescript-logo-small_med.png"></a></a></li>
          <li><a href="/edit/gist:2006604">jQuery UI</a></li>
          <li class="divider"></li>
          <li class="dropdown-submenu">
            <a tabindex="-1" href="#">AngularJS</a>
            <ul class="dropdown-menu">
              <li><a href="/edit/gist:3510140">1.0.6<a href="/edit/gist:3189582" class="coffee" title="In coffee-script"><img src="/img/coffeescript-logo-small_med.png"></a></a></li>
              <li><a href="/edit/gist:5301635">1.0.6 + Jasmine</a></li>
              <li class="divider"></li>
              <li><a href="/edit/gist:3662702">1.1.4 (unstable)<a href="/edit/gist:3662696" class="coffee" title="In coffee-script"><img src="/img/coffeescript-logo-small_med.png"></a></a></li>
            </ul>
          </li>
          <li class="divider"></li>
          <li><a href="/edit/gist:2016721">Bootstrap<a href="/edit/gist:2016721" class="coffee" title="In coffee-script"><img src="/img/coffeescript-logo-small_med.png"></a></a></li>
          <li class="divider"></li>
          <li><a href="/edit/gist:2050713">Backbone.js<a href="/edit/gist:2050746" class="coffee" title="In coffee-script"><img src="/img/coffeescript-logo-small_med.png"></a></a></li>
          <li class="divider"></li>
          <li><a href="/edit/gist:3510115">YUI</a></li>
        </ul>
      </div>
      <div class="btn-group">
        <button ng-click="togglePreview()" class="btn btn-inverse" ng-class="{active: panes.active.id=='preview'}" ng-switch on="panes.active.id=='preview'" tooltip-placement="bottom" tooltip="Preview your work">
          <div ng-switch-when="false">
            <i class="icon-play" />
            <span class="shrink">Run</span>
          </div>
          <div ng-switch-when="true">
            <i class="icon-stop" />
            <span class="shrink">Stop</span>
          </div>
        </button>
      </div>
      <div class="btn-group pull-right">
        <a ng-href="{{url.embed}}/{{session.plunk.id}}/" target="_blank" class="btn" tooltip-placement="bottom" tooltip="Open the embedded view">
          <i class="icon-external-link" />
        </a>
      </div>
      <div class="btn-group pull-right">
        <button ng-click="triggerDownload()" class="btn" tooltip-placement="bottom" tooltip="Download your Plunk as a zip file">
          <i class="icon-download-alt" />
        </button>
      </div>
      <div class="btn-group pull-right" ng-show="session.isSaved() && visitor.isMember()">
        <button ng-click="toggleFavorite()" class="btn" ng-class="{activated: session.plunk.thumbed, 'active': session.plunk.thumbed}" tooltip-placement="bottom" tooltip="Save this Plunk to your favorites">
          <i class="icon-star" />
        </button>
      </div>
      <div class="btn-group pull-right" ng-show="session.isSaved() && visitor.isMember()">
        <button ng-click="toggleRemembered()" class="btn" ng-class="{activated: session.plunk.remembered, 'active': session.plunk.remembered}" tooltip-placement="bottom" tooltip="Save this Plunk to your list of templates">
          <i class="icon-briefcase" />
        </button>
      </div>
    </div>
  """
  link: ($scope, el, attrs) ->
    $scope.session = session
    $scope.panes = panes
    $scope.visitor = visitor
    $scope.url = url
    
    $scope.promptReset = ->
      if session.isDirty() and not session.skipDirtyCheck then notifier.confirm "You have unsaved changes. This action will reset your plunk. Are you sure you would like to proceed?",
        confirm: -> session.reset()
      else session.reset()
    
    $scope.promptDestroy = ->
      notifier.confirm "Confirm Deletion", "Are you sure that you would like to delete this plunk?",
        confirm: -> session.destroy()          
    
    $scope.triggerDownload = ->
      downloader.download session.toJSON(), if session.plunk?.id then "plunk-#{session.plunk.id}.zip" else "plunk.zip"
    
    $scope.toggleFavorite = ->
      if session.plunk then session.plunk.star()
    
    $scope.toggleRemembered = ->
      if session.plunk then session.plunk.remember()
    
    $scope.togglePreview = ->
      previewer = panes.findById("preview")
      panes.toggle(previewer)
]