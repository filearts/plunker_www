#= require ../services/settings

module = angular.module("plunker.panes")

module.requires.push "plunker.url"
module.requires.push "plunker.session"
module.requires.push "plunker.settings"


module.run [ "$q", "$http", "url", "panes", "session", "settings", ($q, $http, url, panes, session, settings) ->

  debounce = (func, threshold, execAsap) ->
    timeout = false
    
    return debounced = ->
      obj = this
      args = arguments
      
      delayed = ->
        func.apply(obj, args) unless execAsap
        timeout = null
      
      if timeout
        clearTimeout(timeout)
      else if (execAsap)
        func.apply(obj, args)
      
      timeout = setTimeout delayed, threshold || 100
      
  panes.add
    id: "preview"
    icon: "eye-open"
    order: 1
    title: "Live Preview"
    description: """
      See a live preview of your code on the web in either a pane or as a pop-out window.
    """
    size: "50%"
    template: """
      <div class="plunker-previewer" ng-class="{loading: loading}">
        <div class="plunker-previewer-ops">
          <div class="btn-toolbar">
            <div class="btn-group" ng-switch on="windowed">
              <button id="refresh-preview" ng-click="refreshPreview()" class="btn btn-mini btn-success" title="Manually trigger a refresh of the preview"><i class="icon-refresh icon-white"></i></button>
              <button id="expand-preview" ng-click="expandWindow()" ng-switch-when="false" class="btn btn-mini btn-primary" title="Launch the preview in a separate window"><i class="icon-fullscreen icon-white"></i></button>
              <button id="expand-preview" ng-click="contractWindow()" ng-switch-when="true" class="btn btn-mini btn-danger" title="Close the child preview window"><i class="icon-remove icon-white"></i></button>
            </div>
          </div>
        </div>
        <iframe class="plunker-previewer-iframe" frameborder="0" width="100%" height="100%" scrolling="auto"></iframe>
      </div>
    """
    link: ($scope, $el, attrs) ->
      pane = @
      
      debouncedRefreshPreview = angular.noop
      
      $previewer = $("iframe.plunker-previewer-iframe", $el)
      
      $scope.session = session
      $scope.windowed = false
      $scope.refreshQueued = false
      $scope.previewId = ""
      $scope.settings = settings
      
      $scope.refreshPreview = ->
        dfd = $q.defer()
        json = files: session.toJSON().files
        
        $scope.loading = true
        
        req = $http.post("#{url.run}/#{$scope.previewId}", json, cache: false)
        
        req.then (res) ->
          loc = $previewer[0].contentWindow.location
          
          if loc is res.data.run_url
            loc.reload(true)
          else
            loc.replace(res.data.run_url)
  
          $previewer.ready ->
            dfd.resolve()
            $scope.loading = false
  
          $scope.previewId = res.data.id
          $scope.refreshQueued = false
        , (err) ->
          dfd.reject(err)
          $scope.loading = false
          
        return $scope.promise = dfd.promise
      
      $scope.$watch "settings.previewer.delay", (delay) ->
        debouncedRefreshPreview = debounce ->
          if pane.active then $scope.refreshPreview()
          else $scope.refreshQueued = true
        , delay || 400
        
      $scope.$watch "session.updated_at", ->
        debouncedRefreshPreview() if settings.previewer.auto_refresh
        
      $scope.$watch "pane.active", (active) ->
        $scope.refreshPreview() if active and ($scope.refreshQueued or !$scope.previewId)
        
      $scope.$watch "refreshQueued", (queued) ->
        if queued then pane.class = "pulse-info"
        else pane.class = ""
]