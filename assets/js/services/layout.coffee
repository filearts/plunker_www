module = angular.module "plunker.service.layout", [
]

module.factory "layout", ["$rootScope", ($rootScope) ->
  base = 
    toolbar:
      anchor: "north"
      size: "40px"
      order: 9
    preview:
      anchor: "south"
      order: 0
      size: "40& - 4px"
      closed: false
      handleOpen: 4
      handleClosed: 0
    templates:
      anchor: "west"
      order: 2
      closed: true
      size: "300px"
    multipane:
      anchor: "east"
      order: 0
      closed: true
      size: "400px"
      handleOpen: 4
      handleClosed: 0
      
  presets = [
    name: "Preview on the right"
    layout:
      preview:
        anchor: "east"
        order: 0
        size: "50& - 4px"

  ,
    name: "Preview at the bottom"
    layout:
      preview:
        anchor: "south"
        order: 1
        size: "40% - 4px"
  ]
  
  service =
    current: base
    currentIndex: null
    presets: presets
    isOpen: (paneId) -> @current?.layout?[paneId].open
    toggle: (paneId) -> @current?.layout?[paneId].open = !@current.layout[paneId].open
      
    setLayout: (idx) ->
      if preset = presets[idx]
        @currentIndex = idx
        
        for item, config of preset.layout
          @current[item] ||= {}
          angular.extend(@current[item], config)
          
        $rootScope.$broadcast "reflow"
      @current
  
  service.setLayout(1) # Default

  service
]