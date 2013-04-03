module = angular.module "plunker.api", []

module.provider "api", ->
  $$definitions = {}
  $$apis = {}
  
  service = null

  define: (name, apiOptions = {}) -> $$definitions[name] = apiOptions
  $get: [ "$http", "$q", "$injector", "url", "visitor", ($http, $q, $injector, url, visitor) ->
    service ||= do ->
      for name, apiOptions of $$definitions then do (name, apiOptions) ->
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
              
              if apiOptions.initialize
                $injector.invoke apiOptions.initialize, @

            
            getUrl: ->
              if @url then @url
              else if id = @[primaryKey] then "#{baseUrl}/#{id}"
              
            
            # Fetch an updated copy of the record from the server and return a
            # Promise
            refresh: (refreshOptions = {}) ->
              record = @
              
              refreshOptions.url ||= record.getUrl() 
              refreshOptions.cache = false
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
                unless inst = identityMap[id]
                  inst = identityMap[id] = new Record(json, instOptions)
                else
                  angular.extend(inst, json)
              else
                inst = new Record(json, instOptions)
              
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
                  results.push api.findOrCreate(parser(json, res)) for json in res.data
                  
                  results.$$refreshing = null
                  results.$$refreshed_at = Date.now()
                                
                  results
                  
                results
          
          api
      
      get: (name) -> $$apis[name]
  ]