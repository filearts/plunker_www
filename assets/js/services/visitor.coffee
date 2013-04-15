#= require ./../../vendor/jquery.cookie/jquery.cookie

#= require ./../services/url
#= require ./../services/notifier


module = angular.module "plunker.visitor", [
  "plunker.url"
  "plunker.notifier"
]

module.factory "visitor", ["$http", "$rootScope", "$window", "url", "notifier", ($http, $rootScope, $window, url, notifier) ->
  new class Visitor
    constructor: ->
      @session = {}
      @user = {}
      @logged_in = false
      
      @applySessionData(_plunker.session) if _plunker?.session

      $.cookie "plnk_session", @session.id,
        expires: 14 # 14 days from now
        path: "/"

      self = @
      
      $rootScope.$watch ( -> self.user?.id ), (user) ->
        self.logged_in = !!user
      
      $window._handleOAuthSuccess = (auth) -> $rootScope.$apply ->
        request = $http.post(self.session.user_url, { service: auth.service, token: auth.token })
        request.then (response) ->
          self.applySessionData(response.data)
        , (error) ->
          notifier.error "Login error", arguments...
      
      $window._handleOAuthError = (error) -> $rootScope.$apply ->
        console.error "AUTH", self, arguments...
        notifier.error "Authentication error", self, arguments...
    
    isMember: -> !!@logged_in
        
    applySessionData: (data) ->
      angular.copy(data.user or {}, @user)
      angular.copy(data, @session)

    login: (width = 1000, height = 650) ->
      screenHeight = screen.height
      left = Math.round((screen.width / 2) - (width / 2))
      top = 0
      if (screenHeight > height)
          top = Math.round((screenHeight / 2) - (height / 2))
      
      login = window.open "#{url.www}/auth/github", "Sign in with Github", """
        left=#{left},top=#{top},width=#{width},height=#{height},personalbar=0,toolbar=0,scrollbars=1,resizable=1
      """

      if login then login.focus()
    
    logout: ->
      self = @
      
      request = $http
        url: @session.user_url
        method: "DELETE"
      
      request.then (response) ->
        self.applySessionData(response.data)
      , (error) ->
        notifier.error "Error logging out", arguments...
]