#= require jquery.cookie/jquery.cookie

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

      _handleOAuthSuccess = (auth) -> $rootScope.$apply ->
        console.log "AUTH", auth
        self.request = $http.post(self.session.user_url, { service: auth.service, token: auth.token })
        self.request.then (response) ->
          self.applySessionData(response.data)
          delete self.request
        , (error) ->
          notifier.error "Login error", arguments...
          delete self.request

      _handleOAuthError = (error) -> $rootScope.$apply ->
        console.error "AUTH", error
        notifier.error "Authentication error", self, arguments...

      $window.addEventListener 'message', (message) =>
        if (typeof message.data == 'string' and matches = message.data.match(/^plunker\.auth\.(.*)/))
          try
            origin = (message.origin || message.originalEvent.origin).replace(/^https?:/, '')

            if origin != window.location.origin.replace(/^https?:/, '')
              return _handleOAuthError('Invalid OAuth source origin')

            payload = JSON.parse(matches[1]);

            if payload.auth then _handleOAuthSuccess(payload.auth)
            else if payload.error then _handleOAuthError(payload.error)
            else _handleOAuthError('Invalid OAuth payload.')
          catch error
            _handleOAuthError('Unable to parse OAuth payload.')

    isMember: -> !!@logged_in
    isLoading: -> !!@request or !!@loginWindow

    applySessionData: (data) ->
      angular.copy(data.user or {}, @user)
      angular.copy(data, @session)

    login: (width = 1000, height = 650) ->
      screenHeight = screen.height
      left = Math.round((screen.width / 2) - (width / 2))
      top = 0
      if (screenHeight > height)
          top = Math.round((screenHeight / 2) - (height / 2))

      authHost = 'https:' + url.www.replace(/^https?:/, '')

      @loginWindow = window.open "#{authHost}/auth/github", "Sign in with Github", """
        left=#{left},top=#{top},width=#{width},height=#{height},personalbar=0,toolbar=0,scrollbars=1,resizable=1
      """

      if @loginWindow then @loginWindow.focus()

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
