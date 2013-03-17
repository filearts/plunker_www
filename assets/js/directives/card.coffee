#= require ./../services/quickview

#= require ./../directives/inlineuser
#= require ./../directives/inlineplunk
#= require ./../directives/taglist

#= require ./../../vendor/jquery-timeago/jquery.timeago

module = angular.module "plunker.card", [
  "plunker.inlineuser"
  "plunker.inlineplunk"
  "plunker.quickview"
  "plunker.plunkinfo"
  "plunker.taglist"
]

module.directive "plunkerCard", [ "$timeout", "$compile", "quickview", "visitor", ($timeout, $compile, quickview, visitor) ->
  restrict: "EAC"
  scope:
    plunk: "="
  template: """
    <div class="plunk" ng-class="{starred: plunk.thumbed, owned: plunk.token}">
      <div class="card">
        <ul class="operations">
          <li><a class="btn" title="Edit this Plunk" ng-href="/edit/{{plunk.id}}"><i class="icon-edit"></i></a></li>
          <li><a class="btn" title="View this Plunk in an overlay" ng-click="showQuickView(plunk, $event)"><i class="icon-play"></i></a></li>
          <li><a class="btn" title="View the detailed information about this Plunk" ng-href="/{{plunk.id}}"><i class="icon-info-sign"></i></a></li>
          <li ng-show="visitor.logged_in && plunk.thumbed"><button title="Unstar this Plunk" class="btn starred" ng-click="plunk.star()"><i class="icon-star"></i></button></li>
          <li ng-show="visitor.logged_in && !plunk.thumbed"><button title="Star this Plunk" class="btn" ng-click="plunk.star()"><i class="icon-star"></i></button></li>
        </ul>
        <h4 title="{{plunk.description}}">{{plunk.description}}</h4>
        <img ng-src="http://immediatenet.com/t/l3?Size=1024x768&URL={{plunk.raw_url}}?_={{plunk.updated_at | date:'yyyy-MM-ddTHH:mm:ssZ'}}" />
        <plunker-taglist tags="plunk.tags"></plunker-taglist>
        <plunker-plunk-info plunk="plunk"></plunker-plunk-info>
        <ul class="meta">
          <li ng-show="plunk.fork_of">
            <plunker-inline-plunk plunk="plunk.parent"><i class="icon-share-alt"></i></plunker-inline-plunk>
          </li>
          <li ng-show="plunk.files['README.md']">
            <a title="Full description of Plunk" ng-href="{{plunk.id}}#README"><i class="icon-info"></i></a>
          </li>
          <li ng-show="plunk.thumbed">
            <a title="You starred this Plunk" ng-href="/users/{{visitor.user.login}}/starred"><i class="icon-pushpin"></i></a>
          </li>
        </ul>
      </div>
      <div class="about">
        <plunker-inline-user user="plunk.user"></plunker-inline-user>
        <abbr class="timeago updated_at" title="{{plunk.updated_at}}" ng-bind="plunk.updated_at | date:'medium'"></abbr>
      </div>
    </div>
  """
  link: ($scope, $el, attrs) ->
    $scope.visitor = visitor
    
    $scope.$watch "plunk.updated_at", ->
      $timeout -> $("abbr.timeago", $el).timeago()
      
    $scope.showQuickView = (plunk, $event) ->
      quickview.show(plunk)
      
      $event.preventDefault()
      $event.stopPropagation()

    $scope.toggleStar = (plunk, $event) ->
      #quickview.show(plunk)
      
      $event.preventDefault()
      $event.stopPropagation()

]