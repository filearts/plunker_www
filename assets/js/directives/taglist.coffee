module = angular.module "plunker.taglist", []

module.directive "plunkerTaglist", [ () ->
  restrict: "E"
  replace: true
  scope:
    tags: "="
  template: """
    <ul class="plunker-taglist">
      <li ng-repeat="tag in tags">
        <a ng-href="/tags/{{tag}}">{{tag}}</a>
      </li>
    </ul>
  """

]
