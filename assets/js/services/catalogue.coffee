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
    basePath: "/catalogue/packages"
    primaryKey: "name"
    
    parser: (json) ->
      json.versions ||= []
      version.dependencies ||= {} for version in json.versions
      json
    
    api:
      find:
        isArray: true
    
    initialize: ->
      @getLatestVersion = (range = "*", options = {}) ->
        latestVersionDef = null
        
        for versionDef in @versions
          if semver.satisfies(versionDef.semver, range)
            unless latestVersionDef
              latestVersionDef = versionDef
          
            else if (!versionDef.unstable or options.unstable) and semver.gt(versionDef.semver, latestVersionDef.semver)
              latestVersionDef = versionDef
        
        latestVersionDef
]

module.service "catalogue", [ "$http", "api", ($http, api) ->
  api.get("catalogue")
]
