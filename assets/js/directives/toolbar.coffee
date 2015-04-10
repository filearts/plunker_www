#= require ./../../vendor/ui-bootstrap/ui-bootstrap-tpls-0.3.0
#= require ./../../vendor/angularytics/dist/angularytics

#= require ./../services/visitor
#= require ./../services/session
#= require ./../services/downloader
#= require ./../services/panes
#= require ./../services/url
#= require ./../services/beautifier

module = angular.module "plunker.toolbar", [
  "plunker.visitor"
  "plunker.session"
  "plunker.downloader"
  "plunker.notifier"
  "plunker.panes"
  "plunker.url"
  "plunker.beautifier"
  
  "angularytics"
  "ui.bootstrap"
]

module.directive "plunkerToolbar", ["$location", "Angularytics", "session", "downloader", "notifier", "panes", "visitor", "url", "beautifier", ($location, Angularytics, session, downloader, notifier, panes, visitor, url, beautifier) ->
  restrict: "E"
  scope: {}
  replace: true
  template: """
    <div class="plunker-toolbar btn-toolbar">
      <div class="btn-group" ng-show="session.isPlunkDirty() && (!session.plunk || session.plunk.isWritable())">
        <button ng-click="session.save() | trackEvent:'Plunk':'Save':'Toolbar'" class="btn btn-primary" tooltip-placement="bottom" tooltip="Save your work as a new Plunk">
          <i class="icon-save"></i><span class="shrink"> Save</span>
        </button>
      </div>
      <div class="btn-group" ng-show="!session.isPlunkDirty() && (!session.plunk || session.plunk.isWritable())">
        <button ng-hide="session.plunk.frozen_version==session.plunk.history.length - 1 && !session.currentRevisionIndex" ng-click="session.freeze() | trackEvent:'Plunk':'Freeze':'Toolbar'" class="btn btn-default" tooltip-placement="bottom" tooltip="Set this version as the version other users will see. You can then keep saving new versions that only you can see.">
          <i class="icon-lock"></i><span class="shrink"> Freeze</span>
        </button>
        <button ng-show="session.plunk.frozen_version==session.plunk.history.length - 1 && !session.currentRevisionIndex" ng-click="session.unfreeze() | trackEvent:'Plunk':'Unfreeze':'Toolbar'" class="btn btn-default" tooltip-placement="bottom" tooltip="Unfreeze this plunk so that no revisions are hidden from other users.">
          <i class="icon-unlock"></i><span class="shrink"> Unfreeze</span>
        </button>
      </div>
      <div class="btn-group" ng-show="session.isSaved()">
        <button ng-click="session.fork() | trackEvent:'Plunk':'Fork':'Toolbar'" class="btn" tooltip-placement="bottom" tooltip="Save your changes as a fork of this Plunk">
          <i class="icon-git-fork"></i><span class="shrink"> Fork</span>
        </button>
        <button ng-if="visitor.isMember()" data-toggle="dropdown" class="btn dropdown-toggle" tooltip-placement="bottom" tooltip="Fork and toggle the privacy of this Plunk"><span class="caret"></span></button>
        <ul ng-if="visitor.isMember()" class="dropdown-menu" ng-switch on="session.private">
          <li ng-switch-when="false"><a ng-click="session.fork({private: true}) | trackEvent:'Plunk':'Fork Private':'Toolbar'">Fork to private plunk</a></li>
          <li ng-switch-when="true"><a ng-click="session.fork({private: false}) | trackEvent:'Plunk':'Fork Public':'Toolbar'">Fork to public plunk</a></li>
        </ul>
      </div>
      <div ng-show="session.plunk.isWritable() && session.plunk.isSaved()" class="btn-group">
        <button ng-click="promptDestroy() | trackEvent:'Plunk':'Destroy':'Toolbar'" class="btn btn-danger" tooltip-placement="bottom" tooltip="Delete the current plunk">
          <i class="icon-trash"></i>
        </button>
      </div>
      <div class="btn-group">
        <button ng-click="promptReset() | trackEvent:'Plunk':'Reset':'Toolbar'" class="btn btn-success" tooltip-placement="bottom" tooltip="Create a new Plunk">
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
              <li><a href="/edit/gist:3510140">1.0.x<a href="/edit/gist:3189582" class="coffee" title="In coffee-script"><img src="/img/coffeescript-logo-small_med.png"></a></a></li>
              <li><a href="/edit/gist:5301635">1.0.x + Jasmine</a></li>
              <li class="divider"></li>
              <li><a href="/edit/gist:3662702">1.1.x (unstable)<a href="/edit/gist:3662696" class="coffee" title="In coffee-script"><img src="/img/coffeescript-logo-small_med.png"></a></a></li>
              <li class="divider"></li>
              <li><a href="/edit/tpl:FrTqqTNoY8BEfHs9bB0f">1.2.x<a href="/edit/tpl:9dz4TT6og6hHx9QAOBT3" class="coffee" title="In coffee-script"><img src="/img/coffeescript-logo-small_med.png"></a></a></li>
              <li class="divider"></li>
              <li><a href="/edit/tpl:rfqcl9AHEoJZEEJxyNn2">1.3.x<a href="/edit/tpl:RJc8D4Z6KMf74ffWOTn5" class="coffee" title="In coffee-script"><img src="/img/coffeescript-logo-small_med.png"></a></a></li>
              <li class="divider"></li>
              <li><a href="/edit/tpl:8rFfZljYNl3z1A4LKSL2">1.4.x<a href="/edit/tpl:zxQbqlOd9vSmkCLQm5ke" class="coffee" title="In coffee-script"><img src="/img/coffeescript-logo-small_med.png"></a></a></li>
              <li class="divider"></li>
              <li><a href="/edit/tpl:BrUl7z1vvZBGWBfSGS8D">2.0.x</a></li>
            </ul>
          </li>
          <li class="divider"></li>
          <li class="dropdown-submenu">
            <a tabindex="-1" href="#">React.js</a>
            <ul class="dropdown-menu">
              <li><a href="/edit/tpl:a3vkhunC1Na5BG6GY2Gf">React.js</a></li>
              <li><a href="/edit/tpl:wxQVHKHmyJVjcBJQsk6q">React.js with addons</a></li>
            </ul>
          </li>
          <li class="divider"></li>
          <li><a href="/edit/gist:2016721">Bootstrap<a href="/edit/gist:2016721" class="coffee" title="In coffee-script"><img src="/img/coffeescript-logo-small_med.png"></a></a></li>
          <li class="divider"></li>
          <li><a href="/edit/gist:2050713">Backbone.js<a href="/edit/gist:2050746" class="coffee" title="In coffee-script"><img src="/img/coffeescript-logo-small_med.png"></a></a></li>
          <li class="divider"></li>
          <li><a href="/edit/gist:3510115">YUI</a></li>
          <li class="divider"></li>
          <li><a href="/edit/tpl:tyvqGwgayf3COZGsB81s">KendoUI</a></li>
        </ul>
      </div>
      <div class="btn-group">
        <button ng-click="togglePreview() | trackEvent:'Multipane':panes.active.id=='preview'&&'Show Preview'||'Hide Preview':'Toolbar'" class="btn btn-inverse" ng-class="{active: panes.active.id=='preview'}" ng-switch on="panes.active.id=='preview'" tooltip-placement="bottom" tooltip="Preview your work">
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
      <div class="btn-group pull-right" ng-show="session.isSaved()">
        <a ng-href="{{url.embed}}/{{session.plunk.id}}/" target="_blank" class="btn" tooltip-placement="bottom" tooltip="Open the embedded view">
          <i class="icon-external-link" />
        </a>
      </div>
      <div class="btn-group pull-right">
        <button ng-click="triggerDownload() | trackEvent:'Plunk':'Download Zip':'Toolbar'" class="btn" tooltip-placement="bottom" tooltip="Download your Plunk as a zip file">
          <i class="icon-download-alt" />
        </button>
      </div>
      <div class="btn-group pull-right" ng-show="session.isSaved() && visitor.isMember()">
        <button ng-click="toggleFavorite() | trackEvent:'Plunk':'Star':'Toolbar'" class="btn" ng-class="{activated: session.plunk.thumbed, 'active': session.plunk.thumbed}" tooltip-placement="bottom" tooltip="Save this Plunk to your favorites">
          <i class="icon-star" />
        </button>
      </div>
      <div class="btn-group pull-right" ng-show="session.isSaved() && visitor.isMember()">
        <button ng-click="toggleRemembered() | trackEvent:'Plunk':session.plunk.remembered && 'Remember' || 'Forget':'Toolbar'" class="btn" ng-class="{activated: session.plunk.remembered, 'active': session.plunk.remembered}" tooltip-placement="bottom" tooltip="Save this Plunk to your list of templates">
          <i class="icon-briefcase" />
        </button>
      </div>
      <div class="btn-group pull-right">
        <button ng-click="beautifier.beautify() | trackEvent:'Plunk':'Beautify':'Toolbar'" class="btn" ng-class="{disabled: !beautifier.isBeautifiable()}" tooltip-placement="bottom" tooltip="Beautify your code">
          <i class="icon-ok" />
        </button>
      </div>
    </div>
  """
  link: ($scope, el, attrs) ->
    $scope.session = session
    $scope.panes = panes
    $scope.visitor = visitor
    $scope.url = url
    $scope.beautifier = beautifier
    
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