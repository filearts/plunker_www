#= require ./../services/url
#= require ./../services/visitor
#= require ./../services/api


module = angular.module "plunker.users", [
  "plunker.url"
  "plunker.visitor"
  "plunker.api"
  "plunker.plunks"
]

module.config ["apiProvider", (apiProvider) ->
  apiProvider.define "users",
    basePath: "/users"
    primaryKey: "login"
    
    api:
      find:
        isArray: true
    
    initialize: ["plunks", "url", (plunks, url) ->
      @getPlunks = (options = {}) ->
        options.url ||= "#{url.api}/users/#{@login}/plunks"
        plunks.query(options)
        
      @getTaggedPlunks = (tag, options = {}) ->
        options.url ||= "#{url.api}/users/#{@login}/plunks/tagged/#{tag}"
        plunks.query(options)
        
      @getFavorites = (options = {}) ->
        options.url ||= "#{url.api}/users/#{@login}/thumbed"
        plunks.query(options)
    ]
]

module.service "users", [ "$http", "api", "plunks", "url", ($http, api, plunks, url) ->
  users = api.get("users")
    
]
