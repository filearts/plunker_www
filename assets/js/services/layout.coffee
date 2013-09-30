module = angular.module "plunker.service.layout", [
]

module.factory "layout", ["$rootScope", ($rootScope) ->
  presets = [
    name: "Preview on the right"
    layout:
      preview:
        anchor: "east"
        order: 0
        size: "50& - 4px"
        open: true
      templates:
        anchor: "west"
        order: 2
        size: "300px"
  ,
    name: "Preview at the bottom"
    layout:
      preview:
        anchor: "south"
        order: 2
        size: "40% - 4px"
        open: true
      templates:
        anchor: "west"
        order: 2
        size: "300px"
  ]
  
  service =
    current: null
    presets: presets
    isOpen: (paneId) -> @current?.layout?[paneId].open
    toggle: (paneId) -> @current?.layout?[paneId].open = !@current.layout[paneId].open
      
    setLayout: (idx) ->
      @current = angular.copy(presets[idx].layout) if presets[idx]
      $rootScope.$broadcast "reflow"
      @current
  
  service.setLayout(0) # Default

  service
]