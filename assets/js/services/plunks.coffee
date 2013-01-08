#= require ../services/url
#= require ../services/visitor
#= require ../services/instantiator
#= require ../services/users


module = angular.module "plunker.plunks", [
  "plunker.url"
  "plunker.visitor"
  "plunker.instantiator"
  "plunker.users"
]


module.run ["instantiator", "plunks", (instantiator, plunks) ->
  instantiator.register "plunks", plunks.findOrCreate
]

module.service "plunks", [ "$http", "$rootScope", "$q", "url", "visitor", "instantiator", ($http, $rootScope, $q, url, visitor, instantiator) ->
  $$plunks = {}
  $$feeds = {}
  
  $$findOrCreate = (json = {}, options = {}) ->
    if json.id
      unless $$plunks[json.id]
        $$plunks[json.id] = new Plunk(json)
      
      plunk = $$plunks[json.id]
      
      angular.extend(plunk, json)
    else
      plunk = new Plunk(json)
    
    plunk.user = instantiator.findOrCreate("users", json.user) if json.user
    
    return plunk
  
  $$mapPlunks = (jsonArray, options = {upsert: true}) ->
    results = []

    for json in jsonArray
      json.$$refreshed_at = new Date()
      
      results.push $$findOrCreate(json, options)

    results
  
  $$findOrCreateFeed = (defaults) ->
    defaults = {id: defaults} if angular.isString(defaults)
    id = defaults.id
    plunk = $$findOrCreate(defaults)
    
    $$feeds[id] ||= do ->
      feed = []
      
      addCreationEvent = (parent) ->
        if plunk.parent
          feed.push
            type: "fork"
            icon: "icon-share-alt"
            date: new Date(plunk.created_at)
            parent: plunk.parent
            user: plunk.user
        else
          feed.push
            type: "create"
            icon: "icon-save"
            date: new Date(plunk.created_at)
            source: plunk.source
            user: plunk.user
        
        plunk.children = plunks.query(url: "#{url.api}/plunks/#{plunk.id}/forks")
        plunk.children.$$refreshing.then (children) ->
          for child in children
            feed.push
              type: "forked"
              icon: "icon-git-fork"
              date: child.created_at
              child: child
              user: child.user
          null

          
      if plunk.$$refreshed_at then addCreationEvent(plunk)
      else if plunk.$$refreshing then plunk.$$refreshing.then(addCreationEvent)
      else plunk.refresh().then(addCreationEvent)
      
      
      return feed    

  
  class Plunk
    constructor: (json) ->
      if plunk = $$plunks[json.id]
        angular.extend(plunk, json)
        return plunk
      
      self = @
      
      angular.copy(json, self)
      
      Object.defineProperty self, "feed", get: ->
        $$findOrCreateFeed(self)
      Object.defineProperty self, "parent", get: ->
        if self.fork_of then $$findOrCreate(id: self.fork_of)
        else null
    
    isWritable: -> !@id or !!@token
    isSaved: -> !!@id
    
    refresh: (options = {}) ->
      self = @
      
      options.params ||= {}
      options.params.sessid = visitor.session.id
      
      self.$$refreshing ||= $http.get("#{url.api}/plunks/#{@id}", options).then (res) ->
        angular.copy(res.data, self)
        
        self.$$refreshing = null
        self.$$refreshed_at = new Date()
        
        self
    
    star: (starred = !@thumbed, options = {}) ->
      self = @
      
      throw new Error("Impossible to star a plunk when not logged in") unless visitor.logged_in
      
      options.params ||= {}
      options.params.sessid = visitor.session.id
      
      success = (res) ->
        self.thumbs = res.data.thumbs
        self.score = res.data.score
        self.thumbed = starred
        
        self.$$refreshing = null
        self.$$refreshed_at = new Date()
        
        self
      
      if starred
        self.$$refreshing ||= $http.post("#{url.api}/plunks/#{@id}/thumb", {}, options).then(success)
      else
        self.$$refreshing ||= $http.delete("#{url.api}/plunks/#{@id}/thumb", options).then(success)
    
    save: (delta = {}, options = {}) ->
      self = @
      
      options.params ||= {}
      options.params.sessid = visitor.session.id
      
      self.$$refreshing ||= $http.post(options.url or "#{url.api}/plunks/#{@id or ''}", delta, options).then (res) ->
        angular.copy(res.data, self)
        
        self.$$refreshing = null
        self.$$refreshed_at = new Date()
        
        self

    destroy: (options = {}) ->
      self = @
      
      options.params ||= {}
      options.params.sessid = visitor.session.id
      
      self.$$refreshing ||= $http.delete("#{url.api}/plunks/#{@id}", options).then (res) ->
        delete $$plunks[self.id]
        angular.copy({}, self)
        
        self

      
  plunks =
    findOrCreate: (defaults = {}) -> $$findOrCreate(defaults, upsert: true)
    
    fork: (id, json, options = {}) ->
      self = @
      
      id = id.id if id.id # Normalize if plunk passed in
      
      options.url ||= "#{url.api}/plunks/#{id}/forks"
      options.params ||= {}
      options.params.sessid = visitor.session.id
      
      
      plunk = $$findOrCreate()
      plunk.save(json, options).then (plunk) ->
        $$plunks[plunk.id] = plunk

    
    query: (options = {}) ->
      results = []
      links = {}
      options = angular.copy(options)
      
      options.params ||= {}
      options.params.sessid = visitor.session.id
      options.params.pp = 12
      
      results.url = options.url || "#{url.api}/plunks"
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
          results.push(plunk) for plunk in $$mapPlunks(res.data)
          
          results.$$refreshing = null
          results.$$refreshed_at = new Date()
          
          results
      )()
      
      return results
]
