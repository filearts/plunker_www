#= require ./../services/panes
#= require ./../services/session
#= require ./../services/plunks
#= require ./../services/url
#= require ./../services/visitor
#= require ./../services/quickview

#= require ./../directives/inlineuser
#= require ./../directives/plunkinfo
#= require ./../directives/timeago
#= require ./../directives/pager
#= require ./../directives/taglist


module = angular.module("plunker.panes")

module.requires.push "plunker.session"
module.requires.push "plunker.plunks"
module.requires.push "plunker.url"
module.requires.push "plunker.visitor"
module.requires.push "plunker.plunkinfo"
module.requires.push "plunker.quickview"
module.requires.push "plunker.timeago"
module.requires.push "plunker.pager"
module.requires.push "plunker.taglist"


module.run [ "panes", "session", "plunks", "url", "visitor", "quickview", (panes, session, plunks, url, visitor, quickview) ->

  panes.add
    id: "templates"
    icon: "briefcase"
    size: 440
    order: 300
    title: "Templates"
    description: """
      Create a new plunk from a template.
    """
    template: """
      <div class="plunker-templates">
        <ul class="nav nav-tabs">
          <li ng-class="{active: filter=='forked'}">
            <a ng-click="filter='forked'">Most popular</a>
          </li>
          <li ng-show="visitor.isMember()" ng-class="{active: filter=='own'}">
            <a ng-click="filter='own'">Saved templates</a>
          </li>
        </ul>
        <div class="alert alert-block" ng-show="filter=='own' && templates.length == 0 && !templates.$$refreshing">
          <h4>You do not have any saved templates</h4>
          <p>To add saved templates, load up a Plunk or gist/template in the editor and hit the briefcase icon at
            the right end of the toolbar.
          </p>
        </div>
        <ul class="nav nav-list">
          <li class="template" ng-repeat="plunk in templates">
            <h4 ng-bind="plunk.description || 'Untitled'"></h4>
            
            <plunker-plunk-info plunk="plunk"></plunker-plunk-info>
            
            <p>
              <plunker-inline-user user="plunk.user"></plunker-inline-user>
              <abbr class="timeago updated_at" title="{{plunk.updated_at}}" ng-bind="plunk.updated_at | date:'medium'"></abbr>
            </p>
            <plunker-taglist class="pull-right" tags="plunk.tags"></plunker-taglist>
            <p>
              <button class="btn btn-mini" ng-click="preview(plunk)">
                <i class="icon-play"></i>
                Preview
              </button>
              <a class="btn btn-mini btn-primary" ng-click="close()" ng-href="/edit/tpl:{{plunk.id}}">
                <i class="icon-file"></i>
                Edit
              </a>
            </p>
          </li>
        </ul>
        <plunker-pager class="pagination-right" collection="templates" nav="moveTo(url)"></plunker-pager>

      </div>
    """
    link: ($scope, $el, attrs) ->
      pane = @
      activated = false
      
      $scope.session = session
      $scope.visitor = visitor
      
      $scope.preview = (plunk) ->
        quickview.show(plunk, hideOperations: true)
      
      $scope.close = ->
        pane.active = false
        
      $scope.moveTo = (url) ->
        $scope.templates.pageTo(url)
      
      $scope.$watch "pane.active", (active) ->
        unless activated
          activated = true
          $scope.filter =
            if visitor.isMember() then "own"
            else "forked"
        
        if active then $scope.templates?.refresh()
      
      $scope.$watch "visitor.isMember()", (member) ->
        if $scope.filter is "own" and !member then $scope.filter = "forked"
      
      $scope.$watch "filter", (filter) ->
        if filter is "forked" then $scope.templates = plunks.query(url: "#{url.api}/plunks/forked")    
        else if filter is "own" then $scope.templates = plunks.query(url: "#{url.api}/plunks/remembered")
        
        $scope.templates.page = 1
      
]