#= require ui-bootstrap/ui-bootstrap-tpls-0.3.0

#= require ./../directives/inlineplunk

module = angular.module "plunker.plunkinfo", [
  "ui.bootstrap"
  
  "plunker.inlineplunk"
]

module.filter "shorten", ->
  (val) ->
    val = parseInt(val, 10)
    
    if val >= 10000 then Math.round(val / 1000) + "k"
    else if val >= 1000 then Math.round(val / 100) / 10 + "k"
    else val

module.directive "plunkerPlunkInfo", [ "$rootScope", ($rootScope) ->
  restrict: "E"
  scope:
    plunk: "="
  replace: true
  template: """
    <ul class="plunk-info">
      <!--<li class="comments" tooltip="Comments and replunks">
        <span><i class="icon-comments"></i>{{plunk.comments.length || 0}}</span>
      </li>-->
      <li class="forks" tooltip="Forks of this plunk">
        <span><i class="icon-git-fork"></i>{{plunk.forks.length}}</span>
      </li>
      <li class="stars" tooltip="{{plunk.thumbed && 'Un-star this plunk' || 'Star this plunk'}}">
        <span><i class="icon-star"></i>{{plunk.thumbs}}</span></a>
      </li>
      <li class="views" tooltip="Views of this plunk">
        <span><i class="icon-eye-open"></i>{{plunk.views | shorten}}</span></a>
      </li>
    </ul>
  """
  link: ($scope, $el, attrs) ->

]