_ = require "lodash"

require "../services/htmlFile.coffee"


module = angular.module "plunker.service.updater", [
  "plunker.service.htmlFile"
]

module.factory "updater", [ "$q", "htmlFile", ($q, htmlFile) ->
  update: (json) ->
    throw new Error("Unable to update invalid json: missing files array") unless json.files and json.files.length
    
    if index = _.find(json.files, (file) -> file.filename is "index.html")
      file = htmlFile.create(index.content)
      file.findDeclaredDependencies()
        .then(file.loadPackageDefinitions)
        .then(file.updateAllPackageTags)
        .then ->
          console.log file
          # Update the index content
          index.content = file.toString()
          
          # Return the updated json
          return json
        
    # If we have no index.html, return the unmodified json, wrapped in a promise
    else $q.when(json)
]