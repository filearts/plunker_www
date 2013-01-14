#= require ../services/plunks
#= require ../services/visitor

#= require ../directives/gallery
#= require ../directives/overlay
#= require ../directives/plunkinfo
#= require ../directives/timeago

module = angular.module "plunker.preview", [
  "plunker.plunks"
  "plunker.visitor"
  "plunker.gallery"
  "plunker.overlay"
  "plunker.plunkinfo"
  "plunker.timeago"
]


module.config ["$routeProvider", ($routeProvider) ->
  $routeProvider.when "/:plunk_id",
    template: """
      <div id="preview" class="container">
        <div class="row">
          <div class="span12">
            <h1>{{plunk.description}} <small>({{plunk.id}})</small></h1>
            <ul class="operations">
              <li>
                <a class="btn btn-primary" ng-href="/edit/{{plunk.id}}">
                  <i class="icon-edit"></i>
                  Launch in Editor
                </a>
              </li>
              <li>
                <a class="btn" ng-href="{{plunk.raw_url}}" target="_blank">
                  <i class="icon-fullscreen"></i>
                  Launch Fullscreen
                </a>
              </li>
              <li ng-show="visitor.logged_in">
                <button class="btn" ng-click="plunk.star()" ng-class="{starred: plunk.thumbed}">
                  <i class="icon-star"></i>
                  <span ng-show="plunk.thumbed">Unstar</span>
                  <span ng-hide="plunk.thumbed">Star</span>
                </button>
              </li>
            </ul>
            <div class="frame">
              <iframe frameborder="0" width="100%" height="100%" ng-src="{{plunk.raw_url}}"></iframe>
            </div>
            
            <div class="about">
              <plunker-plunk-info plunk="plunk"></plunker-plunk-info>
      
              Last saved by
              <plunker-inline-user user="plunk.user"></plunker-inline-user>
              <abbr timeago="plunk.updated_at"></abbr>
              
            </div>
          </div>
        </div>
        <div id="plunk-feed" class="feed">
          <div class="row">
            <div class="span12">
              <h2>Event Feed</h2>
            </div>
          </div>
          <div class="row event" ng-repeat="event in plunk.feed | orderBy:'-date'" ng-class="{{event.type}}" ng-switch on="event.type">
            <hr class="span12"></hr>
            <div ng-switch-when="fork">
              <div class="span1 type"><i ng-class="event.icon"></i></div>
              <div class="span11">
                <plunker-inline-user user="event.user"></plunker-inline-user>
                forked this plunk off of <plunker-inline-plunk plunk="event.parent">{{event.parent.id}}</plunker-inline-plunk>
                by <plunker-inline-user user="event.parent.user"></plunker-inline-user>
                <abbr timeago="event.date"></abbr>.
              </div>
            </div>
            <div ng-switch-when="create">
              <div class="span1 type"><i ng-class="event.icon"></i></div>
              <div class="span11">
                <plunker-inline-user user="event.user"></plunker-inline-user>
                created this plunk
                <abbr timeago="event.date"></abbr>.
              </div>
            </div>
            <div ng-switch-when="forked">
              <div class="span1 type"><i ng-class="event.icon"></i></div>
              <div class="span11">
                <plunker-inline-user user="event.user"></plunker-inline-user>
                created <plunker-inline-plunk plunk="event.child">{{event.child.id}}</plunker-inline-plunk>
                by forking this plunk
                <abbr timeago="event.date"></abbr>.
              </div>
            </div>
          </div>
        </div>
      </div>
      """
    resolve:
      plunk: ["$route", "plunks", ($route, plunks) ->
        if _plunker.bootstrap
          plunk = plunks.findOrCreate(_plunker.bootstrap)
          plunk.$$refreshed_at = Date.now() # Tell the app that this is a *server* copy
        else
          plunk = plunks.findOrCreate(id: $route.current.params.plunk_id)
          plunk.refresh() unless plunk.$$refreshed_at
        plunk
      ]
      
    controller: ["$scope", "$routeParams", "visitor", "plunk", ($scope, $routeParams, visitor, plunk) ->
      $scope.plunk = plunk
      $scope.visitor = visitor
    ]
]