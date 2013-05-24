#= require ./../../vendor/semver/semver

#= require ./../services/url
#= require ./../services/visitor


module = angular.module "plunker.catalogue", [
  "plunker.visitor"
  "plunker.url"
]

module.factory "catalogue", ["$http", "visitor", "url", ($http, visitor, url) ->
  apiUrl = url.api
  
  identityMap = {}
  
  class Package
    constructor: (data = {}) ->
      @update(data)
    
    update: (data = {}) ->
      angular.copy(data, @)
      @
    
    save: (data = {}, options = {}) ->
      pkg = @
      
      throw new Error("Attempting to save a package without a primary key") unless data.name
      
      options.cache = false
      options.params ||= {}
      options.params.sessid = visitor.session.id
      
      payload =
        description: data.description
        homepage: data.homepage
        documentation: data.documentation
        
      request = $http.post("#{apiUrl}/catalogue/packages/#{pkg.name}", payload, options).then (response) ->
        pkg.update(response.data)
        
        delete pkg.then
        delete pkg.$$v
        
        pkg
      
      pkg.then = request.then.bind(request)
      pkg
    
    addVersion: (data = {}, options = {}) ->
      pkg = @
      
      throw new Error("Attempting to add a version without a primary key") unless pkg.name
      
      options.cache = false
      options.params ||= {}
      options.params.sessid = visitor.session.id
      
      payload = 
        semver: data.semver
        unstable: !!data.unstable
      payload.scripts = angular.copy(data.scripts) if data.scripts.length
      payload.styles = angular.copy(data.styles) if data.styles.length
      payload.dependencies = angular.copy(data.dependencies) if data.dependencies.length
        
      request = $http.post("#{apiUrl}/catalogue/packages/#{pkg.name}/versions", payload, options).then (response) ->
        pkg.update(response.data)
        
        delete pkg.then
        delete pkg.$$v
        
        pkg
      
      pkg.then = request.then.bind(request)
      pkg
    
    updateVersion: (data = {}, options = {}) ->
      pkg = @
      
      throw new Error("Attempting to add a version without a primary key") unless pkg.name
      throw new Error("Attempting to update a version without a primary key") unless data.semver
      
      options.cache = false
      options.params ||= {}
      options.params.sessid = visitor.session.id
      
      payload = {unstable: !!data.unstable}
      payload.scripts = angular.copy(data.scripts) if data.scripts.length
      payload.styles = angular.copy(data.styles) if data.styles.length
      payload.dependencies = angular.copy(data.dependencies) if data.dependencies.length
        
      request = $http.post("#{apiUrl}/catalogue/packages/#{pkg.name}/versions/#{data.semver}", payload, options).then (response) ->
        pkg.update(response.data)
        
        delete pkg.then
        delete pkg.$$v
        
        pkg
      
      pkg.then = request.then.bind(request)
      pkg
    
    destroyVersion: (data = {}, options = {}) ->
      pkg = @
      
      throw new Error("Attempting to destroy a version without a primary key") unless pkg.name
      throw new Error("Attempting to destroy a version without a primary key") unless data.semver
      
      options.cache = false
      options.params ||= {}
      options.params.sessid = visitor.session.id
        
      request = $http.delete("#{apiUrl}/catalogue/packages/#{pkg.name}/versions/#{data.semver}", options).then (response) ->
        pkg.update(response.data)
        
        delete pkg.then
        delete pkg.$$v
        
        pkg
      
      pkg.then = request.then.bind(request)
      pkg
    
    bump: (options = {}) ->
      pkg = @
      
      throw new Error("Attempting to bump a package without a primary key") unless pkg.name
      
      options.cache = false
      options.params ||= {}
      options.params.sessid = visitor.session.id
        
      request = $http.post("#{apiUrl}/catalogue/packages/#{pkg.name}/bump", {}, options).then (response) ->
        pkg.update(response.data)

          
    destroy: (options = {}) ->
      pkg = @
      
      throw new Error("Attempting to destroy a package without a primary key") unless pkg.name
      
      options.cache = false
      options.params ||= {}
      options.params.sessid = visitor.session.id
        
      request = $http.delete("#{apiUrl}/catalogue/packages/#{pkg.name}", options).then (response) ->
        pkg.update({})
        
        delete pkg.then
        
        return
      
      pkg.then = request.then.bind(request)
      pkg
          
    refresh: (options = {})->
      pkg = @
      
      throw new Error("Attempting to refresh a package without a primary key") unless pkg.name
      
      options.cache = false
      options.params ||= {}
      options.params.sessid = visitor.session.id
        
      request = $http.get("#{apiUrl}/catalogue/packages/#{pkg.name}", options).then (response) ->
        pkg.update(response.data)
        
        delete pkg.then
        
        pkg
      
      pkg.then = request.then.bind(request)
      pkg
    
    # TODO: This does nothing useful
    getMatchingVersion: (range = "*") ->
      bestMatch = null
      
      return bestMatch unless @versions
      
      for version in @versions when semver.satisfies(version.semver, range) and (not bestMatch or semver.gt(version.semver, bestMatch.semver))
        bestMatch = version
      
      bestMatch
      
    # TODO: This does nothing useful
    getMatchingVersions: (range = "*") ->
      matches = []
      
      matches.push(version) for version in @versions when semver.satisfies(version.semver, range)
      
      matches

  # Coffee-Script will implicitly return the object below
  
  findOne: (data = {}) -> identityMap[data.name] or @fetch(data)
  fetch: (data = {}, options = {}) ->
    throw new Error("Attempting to refresh a package without a primary key") unless data.name
    
    options.cache = false
    options.params ||= {}
    options.params.sessid = visitor.session.id
      
    request = $http.get("#{apiUrl}/catalogue/packages/#{data.name}", options).then (response) ->
      (identityMap[data.name] ||= new Package).update(response.data)

    
  search: (query) -> @findAll(params: query: query)
  # Return an array of trending plunks
  findAll: (options = {}) ->
    options.cache = false
    options.url ||= "#{apiUrl}/catalogue/packages"
    options.params ||= {}
    options.params.sessid = visitor.session.id
    
    links = {}

    packages = []
    packages.loading = true
    packages.links = (rel) ->
      if rel then links[rel] or ""
      else links
    packages.refresh = (url = options.url) ->
      
      request = $http.get(url, options).then (response) ->
        angular.copy {}, links
        
        if link = response.headers("link")
          link.replace /<([^>]+)>;\s*rel="(\w+)"/gi, (match, href, rel) ->
            links[rel] = href
            
        packages.length = 0
        packages.push(new Package(json)) for json in response.data
        
        delete packages.loading
        delete packages.then
        
        packages
      
      packages.then = request.then.bind(request)
      packages
    
    packages.then = -> packages.refresh().then
    packages
  create: (data, options = {}) ->
    options.cache ?= true
    options.url ||= "#{apiUrl}/catalogue/packages"
    options.params ||= {}
    options.params.sessid = visitor.session.id
    
    request = $http.post(options.url, data, options).then (response) ->
      new Package(response.data)
    , (err) -> new Error("Failed to create package" + err.message)
    
]
