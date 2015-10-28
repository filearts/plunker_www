#= require ./../../vendor/script/dist/script

#= require ./../services/panes


module = angular.module("plunker.panes")

module.run [ "$q", "$timeout", "panes", ($q, $timeout, panes) ->
  GitterChat = null
  ((window.gitter = {}).chat = {}).options =
    disableDefaultChat: true
    
  gitterReady = $q.defer();

  document.addEventListener 'gitter-sidecar-ready', (e) ->
    gitterReady.resolve(e.detail.Chat)

  panes.add
    id: "gitter"
    icon: "comments"
    size: "50%"
    title: "Chat"
    description: """
      Real-time discussion.
    """
    template: """
      <div class="plunker-chat gitter-chat-embed">
        Loading Gitter...
      </div>
    """
    link: ($scope, $el, attrs) ->
      pane = @
      chat = null
      linked = true
      loaded = false
      
      document.querySelector('.gitter-chat-embed').addEventListener 'gitter-chat-toggle', (e) ->
        if !e.detail.state then panes.close(pane)
      
      $scope.$watch ( -> pane.active), (active) ->
        if active
          if !loaded
            $script('https://sidecar.gitter.im/dist/sidecar.v1.js')
            loaded = true
      
          gitterReady.promise.then (GitterChat) ->
            if linked
              angular.element($el).html('')
              
              chat = new GitterChat
                room: 'filearts/plunker',
                targetElement: '.gitter-chat-embed'
                showChatByDefault: true
        else
          if chat then chat.destroy()
      
      $scope.$on '$destroy', ->
        if chat then chat.destroy()
        linked = false
]