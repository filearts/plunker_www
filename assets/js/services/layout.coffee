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
      size: "30%"
    multipane:
      anchor: "east"
      order: 0
      closed: true
      size: "400px"
      handleOpen: 4
      handleClosed: 0
      
  presets = [
    name: "Preview on the right"
    img: "/img/horizontal.png"
    layout:
      preview:
        anchor: "east"
        order: 0
        size: "50& - 4px"

  ,
    name: "Preview at the bottom"
    img: "/img/vertical.png"
    layout:
      preview:
        anchor: "south"
        order: 1
        size: "40& - 4px"
      multipane:
        order: 3
  ]
  
  service =
    current: base
    currentIndex: null
    presets: presets
    isOpen: (paneId) -> @current?[paneId].closed
    toggle: (paneId) -> @current?[paneId].closed = !@current[paneId].closed
    close: (paneId) ->  @current?[paneId].closed = true
    open: (paneId) ->  @current?[paneId].closed = false
      
    setLayout: (idx) ->
      if preset = presets[idx]
        @currentIndex = idx
        
        for item, config of preset.layout
          @current[item] ||= {}
          angular.extend(@current[item], config)
          
        $rootScope.$broadcast "reflow"
      @current
  
  service.setLayout(0) # Default

  service
]