require "../services/layout.coffee"


module = angular.module "plunker.service.multipane", [
  "plunker.service.layout"
]

module.factory "multipane", [ "layout", (layout) ->
  panes: {}
  active: null
  add: (name, paneDef) ->
    paneDef.name = name
    
    @panes[name] = paneDef

  activate: (name) ->
    @active = null
    @active = pane for paneName, pane of @panes when paneName is name
  
  toggle: (name) ->
    # Toggle the open state if activation is successful
    layout.current.multipane?.closed = !layout.current.multipane?.closed if @activate(name)
  
  isActive: (name) -> @active is @panes[name]
  isOpen: -> !layout.current.multipane?.closed
]
    
module.directive "plunkerMultipane", [ "$compile", "$injector", "multipane", ($compile, $injector, multipane) ->
  restrict: "A"
  link: ($scope, $element, $attrs) ->
    $scope.$watch (-> multipane.active), (active, previous) ->
      if previous
        $element.removeClass("pane-#{previous.name}")

        $injector.invoke active.onClose, active, $scope: active.scope if active.onClose
      
      if active
        firstOpen = !active.scope
        active.scope ||= $scope.$new()
        $element.html active.template
        
        $compile($element.children())(active.scope)
        
        $element.addClass("pane-#{active.name}")

        $injector.invoke active.onOpen, active, $scope: active.scope if active.onOpen
        $injector.invoke active.controller, active, $scope: active.scope if active.controller and firstOpen
        
]