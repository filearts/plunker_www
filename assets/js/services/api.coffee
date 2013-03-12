module = angular.module "plunker.api", []

module.service "api", [ "$http", "$q", "url", "visitor", ($http, $q, url, visitor) ->
  $$identityMaps = {}
  $$apis = {}
  
  define: (name, apiOptions = {}) ->
    $$apis[name] ||= do ->
      identityMap = @identityMap = {}
      baseUrl = "#{url.api}#{apiOptions.basePath || '/'}"
      primaryKey = apiOptions.primaryKey or "id"
      parser = apiOptions.parser or (json) -> json

      class Record
      
        @prototype[methodName] = methodBody for methodName, methodBody of apiOptions.methods
        
        constructor: (json, constructorOptions = {}) ->
          id = json[primaryKey]
          
          if inst = identityMap[id]
            angular.extend(inst, json)
            return inst
            
          angular.copy parser(json, constructorOptions), @
          
          constructorOptions.initialize?.call(@, json, constructorOptions)
        
        getUrl: ->
          if @url then @url
          else if id = @[primaryKey] then "#{baseUrl}/#{id}"
          
        
        # Fetch an updated copy of the record from the server and return a
        # Promise
        refresh: (refreshOptions = {}) ->
          record = @
          
          refreshOptions.url ||= record.getUrl() 
          refreshOptions.params ||= {}
          refreshOptions.params.sessid = visitor.session.id
      
          return $q.reject("No url property") unless refreshOptions.url
          
          record.$$refreshing = $http.get(refreshOptions.url, refreshOptions).then (res) ->
            angular.extend record, parser(res.data, res)
            
            record.$$refreshing = null
            record.$$refreshed_at = Date.now()
            
            record
        
      api =
        findOrCreate: (json = {}, instOptions = {}) ->
          id = json[primaryKey]
          
          if id
            unless identityMap[id]
              identityMap[id] = new Record(json, instOptions)
            
            inst = identityMap[id]
            
            angular.extend(inst, json)
          else
            inst = new Record(json)
          
          return inst
      
      for method, methodDef of apiOptions.api
        if methodDef.isArray
          api[method] = (methodOptions = {}) ->
            results = []
            
            methodOptions.params ||= {}
            methodOptions.params.sessid = visitor.session.id
            methodOptions.url ||= "#{baseUrl}#{methodDef.path or ''}"
            methodOptions.cache = true
            
            results.$$refreshing = $http.get(methodOptions.url, methodOptions).then (res) ->
              results.push new Record(parser(json, res)) for json in res.data
              
              results.$$refreshing = null
              results.$$refreshed_at = Date.now()
                            
              results
              
            results
      
      api
]

###
api.define "plunks",
  constructor: api.identityMapper(Plunk)
  list:
    path: "/plunks"
    parser: api.arrayMapper(api.identityMapper(Plunk)) # Return a mapping function that instantiates Plunk objects from an identity map
  fork:
    path: "/plunks/:id/forks"
    method: "POST"
    parser: api.identityMapper(Plunk) # Identity mapping function
    
  $fetch:
    path: "/plunks/:id"
    parser: api.identityMapper(Plunk) # Identity mapping function
  $save:
    path: "/plunks/:id"
    method: "POST"
    preparer: "_prepareSavePayload" # A string refers to a method of the resource object
  $delete:
    path: "/plunks/:id"
    method: "DELETE"
    destroyOnSuccess: true
  $star:
    path: "/plunks/:id/thumb"
    method: "POST"
  $unstar:
    path: "/plunks/:id/thumb"
    method: "DELETE"
  $isWritable: -> !@id or !!@token
  $isSaved: -> !!@id
###