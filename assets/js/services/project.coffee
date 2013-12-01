require "../services/api.coffee"
require "../services/dirty.coffee"

module = angular.module "plunker.service.project", [
  "plunker.service.api"
  "plunker.service.dirty"
]


# Service representing the what the user is working on.
#
# Simplied interface over the session service
module.factory "project", [ "$rootScope", "session", "api", "dirty", ($rootScope, session, api, dirty) ->
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
    getFileCount: -> @getFiles().length
    getFiles: -> @getState().files
    
    canSave: -> !@isSaved() or @isOwned()
    
    hasFile: (filenameOrIndex) ->
      if angular.isNumber(filenameOrIndex) then !!@getFileByIndex(filenameOrIndex)
      else if angular.isString(filenameOrIndex) then 0 <= @getIndexByFilename(filenameOrIndex)
    
    isPublic: -> @isSaved() and @plunk.public
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
        json.files = (file for filename, file of json.files)
        
        service.reset angular.copy(json)
        service.plunk = angular.copy(json)
        
        dirty.markClean()
        
        $rootScope.$broadcast "plunkOpenSuccess", service.plunk
    
    fileCreate: (filename, content = "") ->
      client.fileCreate filename, content
      
    fileRename: (filename, newFilename) ->
      client.fileRename filename, newFilename
    
    fileRemove: (filename) ->
      client.fileRemove filename
  
  return service
]