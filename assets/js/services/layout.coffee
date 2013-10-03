module = angular.module "plunker.service.layout", [
]

module.factory "layout", ["$rootScope", ($rootScope) ->
  presets = [
    name: "Preview on the right"
    layout:
      toolbar:
        anchor: "north"
        size: "41px"
        order: 9
      preview:
        anchor: "east"
        order: 0
        size: "50& - 4px"
        handle: 4
      templates:
        anchor: "west"
        order: 2
        size: "300px"
  ,
    name: "Preview at the bottom"
    layout:
      toolbar:
        anchor: "north"
        size: "41px"
        order: 9
      preview:
        anchor: "south"
        order: 2
        size: "40% - 4px"
        handle: 4
      templates:
        anchor: "west"
        order: 2
        size: "300px"
  ]
  
  service =
    current: {}
    presets: presets
    isOpen: (paneId) -> @current?.layout?[paneId].open
    toggle: (paneId) -> @current?.layout?[paneId].open = !@current.layout[paneId].open
      
    setLayout: (idx) ->
      if preset = presets[idx]
        @current[item] = angular.extend(@current[item] or {}, config) for item, config of preset.layout
        $rootScope.$broadcast "reflow"
      @current
  
  service.setLayout(0) # Default

  service
]