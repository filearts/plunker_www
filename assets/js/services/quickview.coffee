#= require ../directives/inlineuser

#= require ../../vendor/jquery-timeago/jquery.timeago

module = angular.module "plunker.quickview", ["plunker.inlineuser"]

module.directive "plunkerQuickView", [ "$timeout", ($timeout) ->
  restrict: "E"
  replace: true
  template: """
    <div class="plunker-quick-view">
      <div class="inner">
        <a class="close" ng-click="close()">&times;</a>
        <div class="preview">
          <iframe frameborder="0" width="100%" height="100%" ng-src="{{plunk.raw_url}}"></iframe>
        </div>
        <div class="about">
          <h1>{{plunk.description}} <small>({{plunk.id}})</small></h1>
          <plunker-inline-user user="plunk.user"></plunker-inline-user>
          <abbr class="timeago updated_at" title="{{plunk.updated_at}}" ng-bind="plunk.updated_at | date:'medium'"></abbr>
          
          <ul class="operations">
            <li>
              <a class="btn btn-primary" ng-click="close()" ng-href="edit/{{plunk.id}}">
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
            <li>
              <a class="btn" ng-click="close()" ng-href="{{plunk.id}}">
                <i class="icon-play"></i>
                View Details
              </a>
            </li>
          </ul>
          <div class="feed">
            <div class="event" ng-repeat="event in plunk.feed | orderBy:'-date'" ng-class="{{event.type}}" ng-switch on="event.type">
              <hr />
              <div ng-switch-when="fork">
                <div class="type"><i ng-class="event.icon"></i></div>
                <div class="details">
                  <plunker-inline-user user="event.user"></plunker-inline-user>
                  forked this plunk off of <plunker-inline-plunk plunk="event.parent">{{event.parent.id}}</plunker-inline-plunk>
                  by <plunker-inline-user user="event.parent.user"></plunker-inline-user>
                  <abbr timeago="event.date"></abbr>.
                </div>
              </div>
              <div ng-switch-when="create">
                <div class="type"><i ng-class="event.icon"></i></div>
                <div class="details">
                  <plunker-inline-user user="event.user"></plunker-inline-user>
                  created this plunk
                  <abbr timeago="event.date"></abbr>.
                </div>
              </div>
              <div ng-switch-when="forked">
                <div class="type"><i ng-class="event.icon"></i></div>
                <div class="details">
                  <plunker-inline-user user="event.user"></plunker-inline-user>
                  created <plunker-inline-plunk plunk="event.child">{{event.child.id}}</plunker-inline-plunk>
                  by forking this plunk
                  <abbr timeago="event.date"></abbr>.
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  """
  link: ($scope, $el, attrs) ->
    $scope.$watch "plunk.updated_at", ->
      $timeout -> $("abbr.timeago", $el).timeago()
]


module.service "quickview", ["$rootScope", "$document", "$compile", "$location", ($rootScope, $document, $compile, $location) ->
  class QuickView
    constructor: (@plunk) ->
      @plunk.refresh() unless @plunk.$$refreshed_at
      
      $scope = $rootScope.$new()
      $body = $document.find("body")
      link = $compile("""<plunker-quick-view plunk="plunk"></plunker-quick-view>""")
      restoreOverflow = $body.css("overflow")
      
      $scope.plunk = @plunk
      
      $scope.close = @close = ->
        if $scope.$parent
          $scope.$destroy()
          $el.remove()
          $body.css("overflow", restoreOverflow)
      
      $el = link($scope)
      
      $body.prepend($el).css("overflow", "hidden")
  
  activeQuickView = null    
  
  show: (plunk) ->
    activeQuickView.close() if activeQuickView
    
    activeQuickView = new QuickView(plunk)
  
  hide: ->
    activeQuickView.close() if activeQuickView
    
    activeQuickView = null
]