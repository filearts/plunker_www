module = angular.module "plunker.plunkinfo", []

module.directive "plunkerPlunkInfo", [ "$rootScope", ($rootScope) ->
  restrict: "E"
  scope:
    plunk: "="
  transclude: true
  replace: true
  template: """
    <ul class="plunk-info">
      <li class="comments" title="Comments and replunks">
        <plunker-inline-plunk plunk="plunk"><i class="icon-comments"></i>{{plunk.comments.length || 0}}</plunker-inline-plunk>
      </li>
      <li class="forks" title="Forks of this plunk">
        <plunker-inline-plunk plunk="plunk"><i class="icon-git-fork"></i>{{plunk.forks.length}}</plunker-inline-plunk>
      </li>
      <li class="stars" title="{{plunk.thumbed && 'Un-star this plunk' || 'Star this plunk'}}">
        <a ng-href="{{plunk.id}}" ng-click="toggleStar(plunk, $event)"><i class="icon-star"></i>{{plunk.thumbs}}</a>
      </li>
    </ul>
  """
  link: ($scope, $el, attrs) ->

]