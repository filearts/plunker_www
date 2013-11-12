require "../services/api.coffee"

module = angular.module "plunker.service.project", [
  "plunker.service.api"
]


# Service representing the what the user is working on.
#
# Simplied interface over the session service
module.factory "project", [ "$rootScope", "session", "api", ($rootScope, session, api) ->
  # Default project
  defaultProject =
    description: "Untitled project"
    tags: []
    files: [
      filename: "index.html"
      content: ""
    ]
  
  # Create an instance of a session client
  client = session.createClient("Project")
  
  # Public interface of the service
  service = new class Project
    constructor: ->
      @plunk = null

    getIndexByFilename: (filename) -> client.getFileIndex(filename)
    getFileByIndex: (index) -> client.getFileByIndex(index)
    getState: -> client.getSnapshot()
    getFiles: -> @getState().files
    
    canSave: -> !@isSaved() or @isOwned()
    
    isSaved: -> angular.isObject(@plunk)
    isOwned: -> @isSaved() and @plunk.token
      
    # Reset the project
    reset: (state = defaultProject) ->
      @plunk = null
      
      client.reset(state)
    
    # Open a plunk and reset the project
    openPlunk: (plunkId) ->
      # Error handled by caller
      api.all("plunks").one(plunkId).get().then (json) ->
        service.reset angular.copy(json)
        service.plunk = angular.copy(json)
        
        $rootScope.$broadcast "plunkOpenSuccess", service.plunk    
    
    fileCreate: (filename, content = "") ->
      client.fileCreate filename, content
      
    fileRename: (indexOrFilename, newFilename) ->
      [fileIndex, file] = @$resolveFile(indexOrFilename)
      
      client.fileRename file.filename, newFilename
    
    fileRemove: (indexOrFilename, newFilename) ->
      [fileIndex, file] = @$resolveFile(indexOrFilename)
      
      client.fileRemove file.filename
  
  return service
]