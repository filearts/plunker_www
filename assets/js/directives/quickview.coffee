#= require ../directives/inlineuser

#= require ../../vendor/jquery-timeago/jquery.timeago

module = angular.module "plunker.quickview", ["plunker.inlineuser"]

module.directive "plunkerQuickView", [ "$timeout", ($timeout) ->
  restrict: "E"
  scope:
    plunk: "="
  replace: true
  template: """
    <div class="plunker-quick-view">
      <div class="preview">
        <iframe frameborder="0" width="100%" height="100%" ng-src="{{plunk.raw_url}}"></iframe>
      </div>
      <div class="about">
        <h1>{{plunk.description}} <small>({{plunk.id}})</small></h1>
        <plunker-inline-user user="plunk.user"></plunker-inline-user>
      </div>
    </div>
  """

]
