#= require ./../../vendor/jquery-timeago/jquery.timeago

#= require ./../directives/addthis
#= require ./../directives/inlineuser
#= require ./../directives/markdown


module = angular.module "plunker.quickview", [
  "plunker.addthis"
  "plunker.inlineuser"
  "plunker.plunkinfo"
]

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
          <h3>{{plunk.description}} <small>({{plunk.id}})</small></h3>

          <p><plunker-taglist tags="plunk.tags"></plunker-taglist></p>

          <plunker-plunk-info plunk="plunk"></plunker-plunk-info>
          
          <plunker-inline-user user="plunk.user"></plunker-inline-user>
          <abbr class="timeago updated_at" title="{{plunk.updated_at}}" ng-bind="plunk.updated_at | date:'medium'"></abbr>
          

          
          <ul class="operations" ng-hide="options.hideOperations">
            <li>
              <a class="btn btn-primary" ng-click="close()" ng-href="edit/{{plunk.id}}">
                <i class="icon-edit"></i>
                Edit
              </a>
            </li>
            <li>
              <a class="btn" ng-href="{{plunk.raw_url}}" target="_blank">
                <i class="icon-fullscreen"></i>
                Fullscreen
              </a>
            </li>
            <li>
              <a class="btn" ng-click="close()" ng-href="{{plunk.id}}">
                <i class="icon-play"></i>
                View Details
              </a>
            </li>
            <li>
              <div class="addthis_default_style addthis_20x20_style" addthis-toolbox addthis-description="{{plunk.description}}" addthis-path="/{{plunk.id}}">
                <a target="_self" class="addthis_button_twitter"></a>
                <a target="_self" class="addthis_button_facebook"></a>
                <a target="_self" class="addthis_button_google_plusone_share"></a>
                <a target="_self" class="addthis_button_linkedin"></a>
                <a target="_self" class="addthis_button_compact"></a>
              </div>
            </li>
          </ul>
          <div class="readme" ng-show="plunk.getReadme()" markdown="plunk.getReadme()"></div>
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
    constructor: (@plunk, options) ->
      @plunk.refresh() unless @plunk.$$refreshed_at
      
      $scope = $rootScope.$new()
      $body = $document.find("body")
      link = $compile("""<plunker-quick-view plunk="plunk"></plunker-quick-view>""")
      restoreOverflow = $body.css("overflow")
      
      $scope.plunk = @plunk
      $scope.options = options
      
      $scope.close = @close = ->
        if $scope.$parent
          $scope.$destroy()
          $el.remove()
          $body.css("overflow", restoreOverflow)
      
      $el = link($scope)
      
      $body.prepend($el).css("overflow", "hidden")
      
      $rootScope.$on "$routeChangeStart", ->
        activeQuickView?.close()
  
  activeQuickView = null    
  
  show: (plunk, options = {}) ->
    activeQuickView.close() if activeQuickView
    
    activeQuickView = new QuickView(plunk, options)
  
  hide: ->
    activeQuickView.close() if activeQuickView
    
    activeQuickView = null
]