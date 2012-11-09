#= require ../directives/inlineuser
#= require ../directives/quickview

#= require ../../vendor/jquery-timeago/jquery.timeago

module = angular.module "plunker.card", ["plunker.inlineuser", "plunker.quickview"]

module.directive "plunkerCard", [ "$timeout", "$compile", ($timeout, $compile) ->
  restrict: "E"
  scope:
    plunk: "="
  replace: true
  template: """
    <div class="plunk" ng-class="{starred: plunk.thumbed, owned: plunk.token}">
      <div class="card">
        <ul class="operations">
          <li><a class="btn" ng-href="edit/{{plunk.id}}"><i class="icon-edit"></i> Edit</a></li>
          <li><button class="btn" ng-click="showQuickView(plunk)"><i class="icon-eye-open"></i> Quick View</button></li>
        </ul>
        <h4 title="{{plunk.description}}">{{plunk.description}}</h4>
        <img ng-src="http://immediatenet.com/t/l3?Size=1024x768&URL={{plunk.raw_url}}?_={{plunk.updated_at | date:'yyyy-MM-ddTHH:mm:ssZ'}}" />
        <ul class="info">
          <li class="forks" title="Forks of this plunk">
            <a ng-href="{{plunk.id}}/forks"><i class="icon-sitemap"></i>{{plunk.forks.length}}</a>
          </li>
          <li class="stars" title="{{plunk.thumbed && 'Un-star this plunk' || 'Star this plunk'}}">
            <a ng-href="{{plunk.id}}" ng-click="toggleStar(plunk)"><i class="icon-star"></i>{{plunk.thumbs}}</a>
          </li>
        </ul>
        <ul class="meta">
          <li ng-show="plunk.fork_of">
            <a title="This plunk is a fork of another" ng-click="showQuickView(plunk.fork_of)" ng-href="{{plunk.fork_of}}"><i class="icon-share-alt"></i></a>
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
      
    $scope.showQuickView = (plunk) ->
      $el.append $compile("""<plunker-quick-view plunk="plunk"></plunker-quick-view>""")($scope)
]