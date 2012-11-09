#= require ../services/url

module = angular.module "plunker.plunks", ["plunker.url"]

module.service "plunks", [ "$http", "$q", "url", ($http, $q, url) ->
  $$plunks = {}
  
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
      results.push $$findOrCreate(json, options)

    results
  
  class Plunk
    constructor: (json) ->
      if plunk = $$plunks[json.id]
        angular.extend(plunk, json)
        return plunk
      
      angular.copy(json, @)
    
    refresh: (options = {}) ->
      self = @
      
      $http.get("#{url.api}/plunks/#{@id}", options).then (res) ->
        angular.copy(res.data, self)
      
      
  findOrCreate: (defaults = {}) -> $$findOrCreate(defaults, upsert: true)
  
  query: (options = {}) ->
    results = []
    
    results.url = options.url || "#{url.api}/plunks"
    
    (results.refresh = ->
      $http.get(results.url + "?pp=12", options).then (res) ->
        results.length = 0
        results.push(plunk) for plunk in $$mapPlunks(res.data)
    )()
    
    return results
]
