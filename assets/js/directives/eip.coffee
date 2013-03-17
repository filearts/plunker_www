module = angular.module "plunker.eip", []

module.directive "eipEdit", [ () ->
  restrict: "E"
  require: "^plunkerEip"
  transclude: true
  replace: true
  template: """
    <form class="eip-form" ng-show="eip.editing" ng-submit="eip.save()">
      <div class="eip-edit" ng-transclude></div>
      <ul class="eip-ops eip-ops-show">
        <li class="eip-op-save"><a ng-click="eip.save()"><i class="icon-ok"></i></a></li>
        <li class="eip-op-cancel"><a ng-click="eip.cancel()"><i class="icon-remove"></i></a></li>
      </ul>
    </form>
  """
  link: ($scope, $el, attrs, eip) ->
    $scope.eip = eip
]

module.directive "eipShow", [ () ->
  restrict: "E"
  require: "^plunkerEip"
  transclude: true
  replace: true
  template: """
    <div ng-hide="eip.editing">
      <div class="eip-show" ng-transclude></div>
      <ul class="eip-ops">
        <li class="eip-op-edit"><a ng-click="eip.edit()"><i class="icon-edit"></i></a></li>
        <li class="eip-op-destroy" ng-show="eip.destroyable"><a ng-click="eip.destroy()"><i class="icon-trash"></i></a></li>
      </ul>
    </div>
  """
  link: ($scope, $el, attrs, eip) ->
    $scope.eip = eip
]

module.directive "plunkerEip", ["$document", ($document) ->
  instances = []
  
  restrict: "A"
  require: "plunkerEip"
  scope:
    onSave: "&eipSave"
    onCancel: "&eipCancel"
    onDestroy: "&eipDestroy"
    model: "=eipModel"
  transclude: true
  template: """
    <div class="eip-container" ng-transclude>
    </div>
  """
  controller: [ "$scope", ($scope) ->
    eip = @

    eip.edit = ->
      eip.original = angular.copy($scope.model)
      eip.editing = angular.copy($scope.model)
    eip.save = ->
      angular.copy eip.editing, $scope.model
      eip.editing = null
      $scope.onSave()
    eip.cancel = ->
      eip.editing = null
      $scope.onCancel()
    eip.destroy = ->
      $scope.onDestroy()
    
    $scope.$watch "model", (model) ->
      eip.model = model

  ]
  link: ($scope, $el, attrs, eip) ->
      
    attrs.$observe "eipDestroy", (onDestroy) ->
      eip.destroyable = !!onDestroy
      
    preventPropagation = (event) ->
      event.preventDefault()
      event.stopPropagation()
      
      otherClick(event)
    
    otherClick = (event) ->
      $scope.$apply -> inst.cancel() for inst in instances when inst != eip
      
    $el.bind "click", preventPropagation
    $document.bind "click", otherClick
    
    instances.push(eip)
    
    $scope.$on "$destroy", ->
      $el.unbind "click", preventPropagation
      $document.unbind "click", otherClick
      instances.splice(idx, 0) unless 0 > (idx = instances.indexOf(eip))
]