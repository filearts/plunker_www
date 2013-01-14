#= require ../services/url
#= require ../services/visitor
#= require ../services/instantiator

module = angular.module "plunker.users", [
  "plunker.url"
  "plunker.visitor"
  "plunker.plunks"
  "plunker.instantiator"
]


module.run ["instantiator", "users", (instantiator, users) ->
  instantiator.register "users", users.findOrCreate
]

module.service "users", [ "$http", "$rootScope", "$q", "url", "visitor", "instantiator", ($http, $rootScope, $q, url, visitor, instantiator) ->
  $$users = {}
  
  $$findOrCreate = (json = {}) ->
    if json.login
      unless $$users[json.login]
        $$users[json.login] = new User(json)
      
      user = $$users[json.login]
      
      angular.extend(user, json)
    else
      user = new User(json)
    
    return user
  
  $$mapUsers = (jsonArray, options = {upsert: true}) ->
    results = []

    for json in jsonArray
      json.$$refreshed_at = new Date()
      
      results.push $$findOrCreate(json, options)

    results

  
  class User
    constructor: (json) ->
      if user = $$users[json.login]
        angular.extend(user, json)
        return user
      
      self = @
      
      angular.copy(json, self)
      
      Object.defineProperty self, "thumbed", get: ->
        plunks.query(url: "#{url.api}/users/#{self.login}/thumbed")
      Object.defineProperty self, "plunks", get: ->
        plunks.query(url: "#{url.api}/users/#{self.login}/plunks")
    
    refresh: (options = {}) ->
      self = @
      
      options.params ||= {}
      options.params.sessid = visitor.session.id
      
      self.$$refreshing ||= $http.get("#{url.api}/users/#{@login}", options).then (res) ->
        angular.copy(res.data, self)
        
        self.$$refreshing = null
        self.$$refreshed_at = new Date()
        
        self

      
  users =
    findOrCreate: (defaults = {}) -> $$findOrCreate(defaults, upsert: true)
    
    query: (options = {}) ->
      results = []
      links = {}
      
      options.params ||= {}
      options.params.sessid = visitor.session.id
      options.params.pp = 12
      
      results.url = options.url || "#{url.api}/users"
      results.links = (rel) ->
        if rel then links[rel] or ""
        else links
          
      results.pageTo = (href) ->
        results.url = href
        results.refresh()
      
      (results.refresh = ->
        results.$$refreshing ||= $http.get(results.url, options).then (res) ->
          angular.copy {}, links
          
          if link = res.headers("link")
            link.replace /<([^>]+)>;\s*rel="(\w+)"/gi, (match, href, rel) ->
              links[rel] = href
          
          results.length = 0
          results.push(plunk) for plunk in $$mapUsers(res.data)
          
          results.$$refreshing = null
          results.$$refreshed_at = new Date()
          
          results
      )()
      
      return results
]
