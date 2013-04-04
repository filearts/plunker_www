#= require ./../services/panes
#= require ./../services/url
#= require ./../services/settings
#= require ./../services/session
#= require ./../services/notifier


module = angular.module("plunker.panes")

module.requires.push "plunker.url"
module.requires.push "plunker.session"
module.requires.push "plunker.settings"
module.requires.push "plunker.notifier"


module.service "previewer", ["$http", "$timeout", "url", "settings", "notifier", ($http, $timeout, url, settings, notifier) ->
]

module.run [ "$q", "$http", "$timeout", "url", "panes", "session", "settings", ($q, $http, $timeout, url, panes, session, settings) ->

  class Preview
    constructor: (options = {}) ->
      @delegate = options.delegate or -> files: {'index.html': {content: ""}}
      @previewId = options.previewId or ""
      @handler = options.handler or ->
    
    refresh: (force = false) ->
      preview = @
      
      $timeout.cancel(@cancelCurrentRefresh) if @cancelCurrentRefresh
      
      @cancelCurrentRefresh = $timeout ->
        json = if angular.isFunction(preview.delegate) then preview.delegate() else preview.delegate
        req = $http.post("#{url.run}/#{preview.previewId}", json, cache: false).then (res) ->
          if res.status >= 400 then notifier.error("Preview refresh failed")
          else
            preview.previewId = res.data.id
            preview.handler(res.data)
            
        , (err) -> notifier.error("Preview refresh failed")
      , if force then 0 else settings.previewer.delay
      
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
        <div ng-hide="windowed">
          <div class="plunker-previewer-ops">
            <div class="btn-toolbar">
              <div class="btn-group" ng-switch on="windowed">
                <button id="refresh-preview" ng-click="refresh()" class="btn btn-mini btn-success" title="Manually trigger a refresh of the preview"><i class="icon-refresh icon-white"></i></button>
                <button id="expand-preview" ng-click="expand()" ng-switch-when="false" class="btn btn-mini btn-primary" title="Launch the preview in a separate window"><i class="icon-fullscreen icon-white"></i></button>
                <button id="expand-preview" ng-click="contract()" ng-switch-when="true" class="btn btn-mini btn-danger" title="Close the child preview window"><i class="icon-remove icon-white"></i></button>
              </div>
            </div>
          </div>
          <iframe class="plunker-previewer-iframe" frameborder="0" width="100%" height="100%" scrolling="auto"></iframe>
        </div>
        <div class="windowed" ng-show="windowed">
          <div class="well">
            <h4>Previeweing in windowed mode</h4>
            <p>You've switched to previewing your work in windowed mode. This can be useful for using the developer tools without having to navigate
              down through the iframe that is used for the in-window preview.</p>
            <p>You can return to the in-window preview at any time simply by clicking below.</p>
            <p>
              <button class="btn btn-danger" ng-click="contract()">
                <i class="icon-remove"></i>
                Close
              </button>
            </p>
          </div>
          <div class="alert alert-block">
            <h4>Auto-refresh disabled</h4>
            <p>While you are in windowed mode, Plunker cannot automatically trigger a refresh of the preview because of cross-domain security.
              To preview your changes, simply hit refresh on the preview window. Plunker should have updated the preview's code automagically for
              you.</p>
          </div>
        </div>
      </div>
    """
    link: ($scope, $el, attrs) ->
      pane = @
      iframe = $("iframe.plunker-previewer-iframe", $el)[0]
      childWindow = null
      
      $scope.session = session
      $scope.windowed = false
      $scope.preview = new Preview
        delegate: -> files: session.toJSON().files
        handler: (data) ->
          if $scope.windowed
            if !childWindow or childWindow?.closed
              childWindow = window.open data.run_url, "plnk_previewer", "resizable=yes,scrollbars=yes,status=yes,toolbar=yes"
            else
              childWindow.location.reload(true) # Fails on recent Chrome... try anyway ;-)
            
          else
            loc = iframe.contentWindow.location
            
            if loc is data.run_url then loc.reload(true)
            else loc.replace(data.run_url)
      
      $scope.refresh = -> $scope.preview.refresh()
      $scope.expand = -> $scope.windowed = true
      $scope.contract = -> $scope.windowed = false
            
      $scope.$watch "windowed", (windowed) ->
        if windowed
          pane.class = "windowed"
          iframe.contentWindow.location.replace("about:blank")
        else
          pane.class = ""
          childWindow?.close()
          childWindow = null
        $scope.preview.refresh() if pane.active
      
      $scope.$watch "pane.active", (active) ->
        if active then $scope.preview.refresh()
        else iframe.contentWindow.location.replace("about:blank")
        
      $scope.$watch "session.updated_at", ->
        $scope.preview.refresh() if settings.previewer.auto_refresh and (pane.active or $scope.windowed)
      
      setInterval ->
        if $scope.windowed and childWindow?.closed
          $scope.$apply ->
            $scope.windowed = false
            childWindow = null
      , 1000
]