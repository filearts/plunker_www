#= require ./../../vendor/qrcodejs/qrcode

#= require ./../services/panes
#= require ./../services/url
#= require ./../services/settings
#= require ./../services/session
#= require ./../services/notifier
#= require ./../services/annotations


module = angular.module("plunker.panes")

module.requires.push "plunker.url"
module.requires.push "plunker.session"
module.requires.push "plunker.settings"
module.requires.push "plunker.notifier"


module.service "previewer", ["$http", "$timeout", "url", "settings", "notifier", ($http, $timeout, url, settings, notifier) ->
]

module.run [ "$q", "$document", "$timeout", "url", "panes", "session", "settings", "notifier", "annotations", ($q, $document, $timeout, url, panes, session, settings, notifier, annotations) ->
  
  genid = (len = 16, prefix = "", keyspace = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789") ->
    prefix += keyspace.charAt(Math.floor(Math.random() * keyspace.length)) while len-- > 0
    prefix
  
  debounce = (delay, fn) ->
    timeout = null
    ->
      context = @
      args = arguments
      
      clearTimeout timeout if timeout
      
      timeout = setTimeout ->
        fn.apply(context, args)
      , delay
      
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
          <iframe name="plunkerPreviewTarget" src="about:blank" class="plunker-previewer-iframe" frameborder="0" width="100%" height="100%" scrolling="auto"></iframe>
        </div>
        <div ng-switch-when="windowed">
          <div class="well">
            <h4>Previewing in windowed mode</h4>
            <p>You've switched to previewing your work in windowed mode. This can be useful for using the developer tools without having to navigate
              down through the iframe that is used for the in-window preview.</p>
            <p>You can return to the in-window preview at any time simply by clicking below.</p>
            <p>You can also scan this QR code to load the preview on your mobile device.</p>
            <p id="preview-qrcode"></p>
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
      @childWindow = null
      
      $scope.previewUrl ||= "#{url.run}/#{genid()}/" # Create a random new preview id
      $scope.iframeUrl = "about:blank" # Initial url until a windowed -> embedded switch
      $scope.session = session
      $scope.mode = "disabled"
      
      $scope.expand = -> $scope.mode = "windowed"
      $scope.contract = -> $scope.mode = if pane.active then "embedded" else "disabled"
      
      $scope.refresh = debounce settings.previewer.delay, ->
        return if $scope.mode is "disabled"
        
        # Disable checking for now. More of a hindrance than benefit
        return if false and do ->
          for filename, notes of annotations
            for annotation in notes when annotation.type is "error"
              $scope.previewBlocker = filename
              console.log "Preview refresh skipped. Syntax errors detected."
              return true
          
          return false
          
        $scope.previewBlocker = ""
        
        form = document.createElement("form")
        form.style.display = "none"
        form.setAttribute "method", "post"
        form.setAttribute "action", $scope.previewUrl
        form.setAttribute "target", "plunkerPreviewTarget"
        
        for filename, file of session.toJSON().files
          field = document.createElement("input")
          field.setAttribute "type", "hidden"
          field.setAttribute "name", "files[#{filename}][content]"
          field.setAttribute "value", file.content
          
          form.appendChild(field)
        
        document.body.appendChild(form)
        
        form.submit()
        
        document.body.removeChild(form)
      
      $scope.$watch "mode", (mode, old_mode) ->
        switch mode
          when "embedded"
            childWindow?.close()
            childWindow = null
          when "windowed"
            pane.childWindow = window.open "about:blank", "plunkerPreviewTarget", "resizable=yes,scrollbars=yes,status=yes,toolbar=yes"
            qrcode = new QRCode "preview-qrcode",
              text: $scope.previewUrl
              width: 256,
              height: 256,
              colorDark : "#000000",
              colorLight : "#ffffff",
              correctLevel : QRCode.CorrectLevel.H
          else
            return # Return to prevent refresh
        
        # Refresh on next tick to make sure DOM udpated first
        setTimeout -> $scope.$apply -> $scope.refresh()
      
      $scope.$watch "pane.active", (active) ->
        if !active and $scope.mode is "embedded" then $scope.mode = "disabled"
        if active and $scope.mode is "disabled" then setTimeout -> $scope.$apply ->
          $scope.mode = "embedded"
        
      $scope.$watch "session.updated_at", ->
        $scope.refresh() if settings.previewer.auto_refresh and (pane.active or $scope.mode is "windowed")
    
      @startInterval($scope)
      
    startInterval: ($scope) ->
      pane = @
      setInterval ->
        if $scope.mode is "windowed" and (!pane.childWindow or pane.childWindow?.closed)
          $scope.$apply ->
            $scope.contract()
            childWindow = null
      , 1000
]
