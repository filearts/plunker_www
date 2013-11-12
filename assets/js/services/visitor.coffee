module = angular.module "plunker.service.visitor", [
]

module.factory "visitor", ["$http", "url", ($http, url) ->
  visitor = {}
  visitor.session = _plunker.session or {}
  
  visitor.login = (identity = {}) ->
    return $q.reject("Login failed - Session data missing") unless visitor.session.user_url
    
    request = $http.post visitor.session.user_url, {},
      params:
        token: identity.token

    request.then (response) ->
      return $q.reject("Login failed - Server error") if response.status >= 400
      
      angular.copy response.data, visitor.session
      
      visitor
    , (err) -> "Login failed - Server error"
  
  visitor.logout = ->
    return $q.reject("Logout failed - Session data missing") unless visitor.session.user_url
    return $q.reject("Logout failed - Not logged in") unless visitor.session.user
    
    request = $http.delete visitor.session.user_url
    
    request.then (response) ->
      return $q.reject("Logout failed - Server error") if response.status >= 400
      
      angular.copy response.data, visitor.session
      
      visitor
    , (err) -> "Logout failed - Server error"
  
  visitor
]