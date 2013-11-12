module = angular.module "plunker.service.oauth", [
]

module.factory "oauth", [ "$window", "$q", "$rootScope", "$timeout", ($window, $q, $rootScope, $timeout) ->
  oauthDeferred = null
  
  postMessageHandler = (e) ->
    if oauthDeferred
      try
        oauthDeferred.resolve(JSON.parse(e.data))
      catch
        angular.noop()
        
  
  $window.addEventListener "message", postMessageHandler
  
  authenticate: ->
    oauth = @
    oauthDeferred = $q.defer()
    resolved = false
    screenHeight = screen.height
    width = 640
    height = 480
    left = Math.round((screen.width / 2) - (width / 2))
    top = 0
    top = Math.round((screenHeight / 2) - (height / 2)) if (screenHeight > height)
    
    authWindow = window.open "/auth/github", "plunker-oauth-window", """
      left=#{left},top=#{top},width=#{width},height=#{height},personalbar=0,toolbar=0,scrollbars=1,resizable=1
    """
    
    authWindow.focus()
    
    cancel = (reason) ->
      ->
        oauthDeferred.reject(reason)
        oauthDeferred = null
        
        clearInterval(interval)
        
        $timeout.cancel(timeout)
        
        null
    
    # Set a timeout on login attempts
    timeout = $timeout cancel("Login timed out"), 1000 * 60 * 2 # 2 minute timeout
    
    # Set a watcher to see if the window closed without logging in
    interval = setInterval ->
      if !authWindow or authWindow.closed != false
        $rootScope.$apply cancel("Auth window closed withotu logging in")
    , 200
    
    oauthDeferred.promise.then (json) ->
      if json.event and json.event is "auth_data" then json.message
      else if json.event and json.event is "auth_error" then $q.reject(json.message)
      else
        console.log "[WARN] Got unknown message", json
        $q.reject("Unknown login payload")
]