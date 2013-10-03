module = angular.module "fa.borderLayout", [
]

throttle = (delay, fn) ->
  throttled = false
  ->
    return if throttled
    
    throttled = true
    setTimeout ->
      throttled = false
    , delay
    
    fn.call(@, arguments...)

class Region
  constructor: (@width = 0, @height = 0) ->
    @top = 0
    @right = 0
    @bottom = 0
    @left = 0
    
  calculateSize: (orientation, target = 0) ->
    total = @getSize(orientation)
    available = @getAvailableSize(orientation)
    
    if angular.isNumber(target)
      if target >= 1 then return Math.round(target)
      if target >= 0 then return Math.round(target * total)
      
      return 0
    
    # Kill whitespace
    target = target.replace /\s+/mg, ""
    
    # Allow for complex sizes, e.g.: 50% - 4px
    if (terms = target.split("-")).length > 1 then return @calculateSize(orientation, terms.shift()) - @calculateSize(orientation, terms.join("+"))
    if (terms = target.split("+")).length > 1 then return @calculateSize(orientation, terms.shift()) + @calculateSize(orientation, terms.join("+"))
      
    if matches = target.match /^(\d+)px$/ then return parseInt(matches[1], 10)
    if matches = target.match /^(\d+(?:\.\d+)?)&$/ then return Math.round(available * parseFloat(matches[1]) / 100)
    if matches = target.match /^(\d+(?:\.\d+)?)%$/ then return Math.round(total * parseFloat(matches[1]) / 100)
    
    throw new Error("Unsupported size: #{target}")
  
  consume: (anchor, size = 0) ->
    switch anchor
      when "north"
        style = { top: "#{@top}px", right: "#{@right}px", left: "#{@left}px", height: "#{size}px" }
        @top += size
      when "east"
        style = { top: "#{@top}px", right: "#{@right}px", bottom: "#{@bottom}px", width: "#{size}px" }
        @right += size
      when "south"
        style = { right: "#{@right}px", bottom: "#{@bottom}px", left: "#{@left}px", height: "#{size}px" }
        @bottom += size
      when "west"
        style = { top: "#{@top}px", bottom: "#{@bottom}px", left: "#{@left}px", width: "#{size}px" }
        @left += size
      
    style
    
  getInnerRegion: ->
    new Region @width - @right - @left, @height - @top - @bottom
  
  getSize: (orientation) ->
    switch orientation
      when "vertical" then @height
      when "horizontal" then @width
  
  getAvailableSize: (orientation) ->
    switch orientation
      when "vertical" then @height - @top - @bottom
      when "horizontal" then @width - @right - @left
  
  

module.directive "pane", [ ->
  restrict: "E"
  replace: true
  require: ["pane", "^borderLayout"]
  transclude: true
  scope: true
  template: """
    <div class="border-layout-pane">
      <div class="border-layout-pane-overlay" ng-style="styleContent"></div>
      <div class="border-layout-pane-handle" layout-handle ng-style="styleHandle"></div>
      <div class="border-layout-pane-scroller" ng-style="styleContent" ng-transclude></div>
    </div>
  """
  controller: ["$scope", "$element", "$attrs", ($scope, $element, $attrs) ->
    pane = @
    
    [$overlay, $handle, $scroller] = $element.children()
    
    $scope.$watch $attrs.options, (options, oldOptions) ->
      if options
        pane.anchor = options.anchor or "center"
        pane.orientation = pane.getOrientation(pane.anchor)
        pane.target = options.size
        pane.max = options.max || Number.MAX_VALUE
        pane.min = options.min || 0
        pane.open = !options.closed
        pane.order = parseInt(options.order or 0, 10)
        pane.handleSize = parseInt(options.handle or 0, 10)
        
        pane.layout.reflow()
    , true
      
    @children = []
    @openSize = 0
    
    @attachChild = (child) -> @children.push(child)
    
    @getOrientation = (anchor = pane.anchor) ->
      switch anchor
        when "north", "south" then "vertical"
        when "east", "west" then "horizontal"
    
    @getContentStyle = (anchor, handleSize) ->
      style =
        top: 0
        right: 0
        bottom: 0
        left: 0
        
      switch anchor
        when "north" then style.bottom = "#{handleSize}px"
        when "east" then style.left = "#{handleSize}px"
        when "south" then style.top = "#{handleSize}px"
        when "west" then style.right = "#{handleSize}px"
      
      style
        
    @getHandleStyle = (anchor, region, handleSize) ->
      
      switch anchor
        when "north"
          height: "#{region.calculateSize('vertical', handleSize)}px"
          right: 0
          left: 0
          bottom: 0
        when "south" 
          height: "#{region.calculateSize('vertical', handleSize)}px"
          right: 0
          left: 0
          top: 0
        when "east"
          width: "#{region.calculateSize('horizontal', handleSize)}px"
          top: 0
          bottom: 0
          left: 0
        when "west" 
          width: "#{region.calculateSize('horizontal', handleSize)}px"
          top: 0
          bottom: 0
          right: 0
    
    @onHandleDown = ->
      $element.addClass("active")
      @layout.onHandleDown()
    @onHandleUp = ->
      $element.removeClass("active")
      @layout.onHandleUp()
    
    @toggle = (open = !pane.open) ->
      pane.open = open
      
      if !open then @openSize = @size
      else @size = @openSize
      
      if open then $element.removeClass("closed")
      else $element.addClass("closed")
      
      @layout.reflow()
    
    @reflow = (region, target = pane.target) ->
      anchor = pane.anchor
      
      if open then $element.removeClass("closed")
      else $element.addClass("closed")
      
      if anchor is "center"
        $element.css
          top: "#{region.top}px"
          right: "#{region.right}px"
          bottom: "#{region.bottom}px"
          left: "#{region.left}px"
      else if anchor in ["north", "east", "south", "west"]
        orientation = @getOrientation(anchor)
        handleSize = region.calculateSize(orientation, pane.handleSize || 0)

        if !pane.open
          size = handleSize
        else
          size = region.calculateSize(orientation, target)
          
          size = Math.min(size, region.calculateSize(orientation, pane.max))
          size = Math.max(size, region.calculateSize(orientation, pane.min))
          size = Math.min(size, region.getAvailableSize(orientation))
          size = Math.max(size, handleSize + 2) # Why does 1.5 work!?
        
        @size = size
        
        styleContainer = region.consume(anchor, size)
        styleContent = @getContentStyle(anchor, handleSize)
        styleHandle = @getHandleStyle(anchor, region, handleSize)
        
        $element.attr("style", "").css(styleContainer)
        
        angular.element($overlay).attr("style", "").css(styleContent)
        angular.element($scroller).attr("style", "").css(styleContent)
        angular.element($handle).attr("style", "").css(styleHandle)
        
      if @children.length
        inner = region.getInnerRegion()
        inner = child.reflow(inner) for child in @children

      return region
    
    @resize = (target) ->
      pane.target = target || 0
      
      @layout.reflow()
      
  ]
  link: ($scope, $el, $attrs, [pane, parent]) ->
    pane.layout = parent
    parent.attachChild(pane)
    
    $scope.$$nextSibling.pane = pane
    
    $scope.$watch "constrained", (constrained) ->
      if constrained then $el.addClass("border-layout-constrained")
      else $el.removeClass("border-layout-constrained")
]

module.directive "layoutHandle", [ "$window", ($window) ->
  restrict: "A"
  require: ["?^pane", "^?borderLayout"]
  link: ($scope, $element, $attrs, [pane, layout]) ->
    return unless pane
    
    el = $element[0]
    
    clickRadius = 5
    clickTime = 300
    
    $scope.$watch ( -> pane.getOrientation() ), (orientation) ->
      $element.removeClass("vertical")
      $element.removeClass("horizontal")
      switch orientation
        when "vertical" then $element.addClass("vertical")
        when "horizontal" then $element.addClass("horizontal")
    
    el.addEventListener "mousedown", (e) ->
      return unless e.button is 0
      
      anchor = pane.anchor
      
      if anchor in ["north", "south"] then coord = "screenY"
      else if anchor in ["west", "east"] then coord = "screenX"

      if anchor in ["north", "west"] then scale = 1
      else if anchor in ["south", "east"] then scale = -1
    
      startPos = {x: e.screenX, y: e.screenY}
      startCoord = e[coord]
      startSize = pane.size
      startTime = Date.now()
      
      pane.onHandleDown()
      
      # Not sure if this really adds value, but added for compatibility
      el.unselectable = "on"
      el.onselectstart = -> false
      el.style.userSelect = el.style.MozUserSelect = "none"
      
      # Null out the event to re-use e and prevent memory leaks
      #e.setCapture()
      e.preventDefault()
      e.defaultPrevented = true
      e = null
      
      handleClick = (e) ->
        $scope.$apply -> pane.toggle()
          
      handleMouseMove = (e) ->
        $element.addClass("border-layout-pane-moving")
      
        # Inside Angular's digest, determine the ideal size of the element
        # according to movements then determine if those movements have been
        # constrained by boundaries, other panes or min/max clauses
        $scope.$apply -> pane.resize targetSize = startSize + scale * (e[coord] - startCoord)

        # Null out the event in case of memory leaks
        #e.setCapture()
        e.preventDefault()
        e.defaultPrevented = true
        e = null
        
      handleMouseUp = (e) ->
        displacementSq = Math.pow(e.screenX - startPos.x, 2) + Math.pow(e.screenY - startPos.y, 2)
        timeElapsed = Date.now() - startTime

        $window.removeEventListener "mousemove", handleMouseMoveThrottled, true
        $window.removeEventListener "mouseup", handleMouseUp, true
        
        cleanup = ->
          # Null out the event in case of memory leaks
          #e.releaseCapture()
          e.preventDefault()
          e.defaultPrevented = true
          e = null

          pane.onHandleUp()
        
 
        if displacementSq <= Math.pow(clickRadius, 2) and timeElapsed <= clickTime
          handleClick(e)
          cleanup()
          return
          
        # In case the mouse is released at the end of a throttle period
        handleMouseMove(e)
        
        cleanup()

      
      # Prevent the reflow logic from happening too often
      handleMouseMoveThrottled = throttle(10, handleMouseMove)
    
      $window.addEventListener "mousemove", handleMouseMoveThrottled, true
      $window.addEventListener "mouseup", handleMouseUp, true

]


module.directive "borderLayout", [ "$window", "$timeout", ($window, $timeout)->
  restrict: "E"
  replace: true
  require: ["borderLayout", "^?pane"]
  transclude: true
  template: """
    <div class="border-layout" ng-transclude>
    </div>
  """
  controller: ["$scope", "$element", "$attrs", ($scope, $element, $attrs) ->
    layout = @
    
    @children = []
    
    @attachChild = (child) ->
      @children.push(child)
    
    @onHandleDown = -> $element.addClass("active")
    @onHandleUp = ->
      $element.removeClass("active")
      $scope.$broadcast "border-layout-reflow"
    
    @reflow = (region) ->
      return if layout.reflowing
      
      layout.reflowing = true
      
      width = $element[0].offsetWidth
      height = $element[0].offsetHeight
      
      region ||= new Region(width, height)
      
      @children.sort (a, b) -> b.order - a.order
      
      region = child.reflow(region) for child in @children

      $scope.$broadcast "border-layout-reflow", Date.now()
      
      layout.reflowing = false
      
  ]
  link: ($scope, $el, $attrs, [layout, parent]) ->
    parent.attachChild(layout) if parent
    
    $scope.$on "border-layout-reflow", ->
      layout.reflow() unless parent
    
    $window.addEventListener "resize", (e) ->
      e.stopPropagation()
      $scope.$apply -> layout.reflow()
    
    $timeout -> layout.reflow() unless parent
]