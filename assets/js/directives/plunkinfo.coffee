#= require ../directives/inlineplunk

module = angular.module "plunker.plunkinfo", [
  "plunker.inlineplunk"
]

module.directive "plunkerPlunkInfo", [ "$rootScope", ($rootScope) ->
  restrict: "E"
  scope:
    plunk: "="
  replace: true
  template: """
    <ul class="plunk-info">
      <li class="comments" title="Comments and replunks">
        <span><i class="icon-comments"></i>{{plunk.comments.length || 0}}</span>
      </li>
      <li class="forks" title="Forks of this plunk">
        <span><i class="icon-git-fork"></i>{{plunk.forks.length}}</span>
      </li>
      <li class="stars" title="{{plunk.thumbed && 'Un-star this plunk' || 'Star this plunk'}}">
        <span><i class="icon-star"></i>{{plunk.thumbs}}</span></a>
      </li>
    </ul>
  """
  link: ($scope, $el, attrs) ->

]