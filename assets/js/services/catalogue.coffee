#= require ./../../vendor/semver/semver

#= require ./../services/url
#= require ./../services/visitor
#= require ./../services/api


module = angular.module "plunker.catalogue", [
  "plunker.url"
  "plunker.visitor"
  "plunker.api"
]

module.config [ "apiProvider", (apiProvider) ->
  apiProvider.define "catalogue", 
    basePath: "/packages"
    primaryKey: "name"
    
    parser: (json) ->
      json.versions ||= []
      version.dependencies ||= {} for version in json.versions
      json
    
    api:
      find:
        isArray: true
    
    initialize: ->
      @getLatestVersion = (unstable = false) ->
        latestVersionDef = null
        
        for versionDef in @versions
          unless latestVersionDef
            latestVersionDef = versionDef
        
          else if (!versionDef.unstable or unstable) and semver.gt(versionDef.semver, latestVersionDef.semver)
            latestVersionDef = versionDef
        
        latestVersionDef
]

module.service "catalogue", [ "$http", "api", ($http, api) ->
  api.get("catalogue")
]
