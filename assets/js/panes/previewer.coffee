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

module.run [ "$q", "$document", "$timeout", "url", "panes", "session", "settings", "notifier", ($q, $document, $timeout, url, panes, session, settings, notifier) ->
  
  genid = (len = 16, prefix = "", keyspace = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789") ->
    prefix += keyspace.charAt(Math.floor(Math.random() * keyspace.length)) while len-- > 0
    prefix
      
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
      <div class="plunker-previewer" ng-switch on="mode">
        <div ng-switch-when="embedded">
          <div class="plunker-previewer-ops">
            <div class="btn-toolbar">
              <div class="btn-group">
                <button id="refresh-preview" ng-click="refresh()" class="btn btn-mini btn-success" title="Manually trigger a refresh of the preview"><i class="icon-refresh icon-white"></i></button>
                <button id="expand-preview" ng-click="expand()" class="btn btn-mini btn-primary" title="Launch the preview in a separate window"><i class="icon-fullscreen icon-white"></i></button>
              </div>
            </div>
          </div>
          <iframe name="plunkerPreviewTarget" src="{{iframeUrl}}" class="plunker-previewer-iframe" frameborder="0" width="100%" height="100%" scrolling="auto"></iframe>
        </div>
        <div ng-switch-when="windowed">
          <div class="well">
            <h4>Previeweing in windowed mode</h4>
            <p>You've switched to previewing your work in windowed mode. This can be useful for using the developer tools without having to navigate
              down through the iframe that is used for the in-window preview.</p>
            <p>You can return to the in-window preview at any time simply by clicking below.</p>
            <p>
              <button class="btn btn-success" ng-click="refresh()">
                <i class="icon-refresh"></i>
                Refresh
              </button>
              <button class="btn btn-danger" ng-click="contract()">
                <i class="icon-remove"></i>
                Close
              </button>
            </p>
          </div>
        </div>
      </div>
    """
    link: ($scope, $el, attrs) ->
      pane = @
      iframe = $("iframe.plunker-previewer-iframe", $el)[0]
      childWindow = null
      
      $scope.previewUrl ||= "#{url.run}/#{genid()}/" # Create a random new preview id
      $scope.iframeUrl = "about:blank" # Initial url until a windowed -> embedded switch
      $scope.session = session
      $scope.mode = "disabled"
      
      $scope.expand = -> $scope.mode = "windowed"
      $scope.contract = -> $scope.mode = "embedded"
      
      $scope.refresh = -> $timeout ->
        return if $scope.mode is "disabled"
        
        form = angular.element("""<form style="display: none;" method="post" action="#{$scope.previewUrl}" target="plunkerPreviewTarget"><form>""")
        
        for filename, file of session.toJSON().files
          field = angular.element("""<input type="hidden" name="files[#{filename}][content]">""")
          field.attr "value", file.content
          
          form.append(field)
        
        #$document.append(form)
        
        form.submit()
        
        $timeout -> form.remove()
      
      $scope.$watch "mode", (mode, old_mode) ->
        switch mode
          when "embedded"
            childWindow?.close()
            childWindow = null
          
            $timeout -> $scope.refresh() # Refresh on next tick to make sure DOM udpated first
          when "windowed"
            childWindow = window.open "about:blank", "plunkerPreviewTarget", "resizable=yes,scrollbars=yes,status=yes,toolbar=yes"
            $timeout -> $scope.refresh() # Refresh on next tick to make sure DOM udpated first
            
      
      $scope.$watch "pane.active", (active) ->
        if !active and $scope.mode is "embedded" then $scope.mode = "disabled"
        if active and $scope.mode is "disabled" then $timeout ->
          $scope.mode = "embedded"
        
      $scope.$watch "session.updated_at", ->
        $scope.refresh() if settings.previewer.auto_refresh and (pane.active or $scope.mode is "windowed")
      
      setInterval ->
        if $scope.mode is "windowed" and childWindow?.closed
          $scope.$apply ->
            $scope.contract()
            childWindow = null
      , 1000
]