#= require ../services/url
#= require ../services/visitor

module = angular.module "plunker.plunks", ["plunker.url"]


module.service "plunks", [ "$http", "$rootScope", "$q", "url", "visitor", ($http, $rootScope, $q, url, visitor) ->
  $$plunks = {}
  $$feeds = {}
  
  $$findOrCreate = (json, options = {upsert: false}) ->
    if json.id
      unless $$plunks[json.id]
        $$plunks[json.id] = new Plunk(json)
      
      plunk = $$plunks[json.id]
      
      angular.extend(plunk, json) if options.upsert
    else
      plunk = new Plunk(json)
    
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

    save: (delta = {}, options = {}) ->
      self = @
      
      options.params ||= {}
      options.params.sessid = visitor.session.id
      
      self.$$refreshing ||= $http.post("#{url.api}/plunks/#{@id or ''}", delta, options).then (res) ->
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
    
    query: (options = {}) ->
      results = []
      
      options.params ||= {}
      options.params.sessid = visitor.session.id
      options.params.pp = 12
      
      results.url = options.url || "#{url.api}/plunks"
      
      (results.refresh = ->
        results.$$refreshing ||= $http.get(results.url, options).then (res) ->
          results.length = 0
          results.push(plunk) for plunk in $$mapPlunks(res.data)
          
          results.$$refreshing = null
          results.$$refreshed_at = new Date()
          
          results
      )()
      
      return results
]
