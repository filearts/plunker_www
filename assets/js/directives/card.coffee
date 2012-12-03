#= require ../services/quickview

#= require ../directives/inlineuser
#= require ../directives/inlineplunk

#= require ../../vendor/jquery-timeago/jquery.timeago

module = angular.module "plunker.card", [
  "plunker.inlineuser"
  "plunker.inlineplunk"
  "plunker.quickview"
  "plunker.plunkinfo"
]

module.directive "plunkerCard", [ "$timeout", "$compile", "quickview", ($timeout, $compile, quickview) ->
  restrict: "EAC"
  scope:
    plunk: "="
  template: """
    <div class="plunk" ng-class="{starred: plunk.thumbed, owned: plunk.token}">
      <div class="card">
        <ul class="operations">
          <li><a class="btn" ng-href="/edit/{{plunk.id}}"><i class="icon-edit"></i> Edit</a></li>
          <li><a class="btn" ng-click="showQuickView(plunk, $event)"><i class="icon-eye-open"></i> Quick View</a></li>
          <li><a class="btn" ng-href="/{{plunk.id}}"><i class="icon-play"></i> View Details</a></li>
        </ul>
        <h4 title="{{plunk.description}}">{{plunk.description}}</h4>
        <img ng-src="http://immediatenet.com/t/l3?Size=1024x768&URL={{plunk.raw_url}}?_={{plunk.updated_at | date:'yyyy-MM-ddTHH:mm:ssZ'}}" />
        <plunker-plunk-info plunk="plunk"></plunker-plunk-info>
        <ul class="meta">
          <li ng-show="plunk.fork_of">
            <plunker-inline-plunk plunk="plunk.parent"><i class="icon-share-alt"></i></plunker-inline-plunk>
          </li>
          <li ng-show="plunk.files['README.md']">
            <a title="Full description of Plunk" ng-href="{{plunk.id}}#README"><i class="icon-info"></i></a>
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