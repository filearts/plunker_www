#= require ../../vendor/semver/semver

#= require ../services/catalogue

module = angular.module "plunker.builder", [
  "plunker.catalogue"
]

module.service "builder", [ "catalogue", (catalogue) ->
  class Build
    addScript: (url) ->
    addStyle: (url) ->
    addDependency: (name, semver) ->
      
]