require "../services/htmlFile.coffee"


module = angular.module "plunker.service.updater", [
  "plunker.service.htmlFile"
]

module.factory "updater", [ "$q", "htmlFile", ($q, htmlFile) ->
  update: (json) ->
    throw new Error("Unable to update invalid json: missing files array") unless json.files and json.files.length
    
    promises = []
    
    for file in json.files then do (file) ->
      if file.filename.match /\.html$/i
        promises.push htmlFile.update(file.content).then (markup) ->
          file.content = markup
    
    $q.all(promises).then -> json

]