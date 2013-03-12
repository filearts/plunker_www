#= require ../../vendor/semver/semver

#= require ../services/url
#= require ../services/visitor
#= require ../services/api


module = angular.module "plunker.catalogue", [
  "plunker.url"
  "plunker.visitor"
  "plunker.api"
]

module.service "catalogue", [ "$http", "api", ($http, api) ->
  class Package
    constructor: (pkgDef) ->
      angular.copy pkgDef, @
      
      for version of @versions
        version.semver = version.version
        delete version.version
     
      
  api.define "packages",
    constructor: Package
    basePath: "/packages"
    primaryKey: "name"
    
    parser: (json) ->
      
      json
    
    api:
      find:
        isArray: true
    
    methods:
      getLatestVersion: (unstable = false) ->
        latestVersionDef = null
        
        for versionDef in @versions
          unless latestVersionDef
            latestVersionDef = versionDef
        
          else if (!versionDef.unstable or unstable) and semver.gt(versionDef.semver, latestVersionDef.semver)
            latestVersionDef = versionDef
        
        latestVersionDef
          
    
]
