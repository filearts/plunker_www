require "../services/project.coffee"


module = angular.module "plunker.service.workspace", [
  "plunker.service.project"
]


# Service representing the state of the plunker editor interface
#
# 
module.factory "workspace", [ "project", (project) ->
  service = new class Workspace
    constructor: ->
      @splits = [0]
      @activeSplitIndex = 0
      @activeFileIndex = 0
    
    $resolveFile: (indexOrFilename) ->
      fileIndex =
        if angular.isNumber(indexOrFilename) then indexOrFilename
        else project.getIndexByFilename(indexOrFilename)
  
      file = project.getFileByIndex(fileIndex)
      
      # Return a tuple of (fileIndex, file)
      return [fileIndex, file]
    
    # Get the index of the active pane
    getActiveSplitIndex: -> @activeSplitIndex
    
    # Get the index of the active split
    getActiveFileIndex: -> @activeFileIndex
    
    # Return an array of open splits with their corresponding file indices
    getActiveSplitIndices: -> @splits
    
    isFileOpen: (indexOrFilename, options = {}) ->
      [fileIndex, file] = @$resolveFile(indexOrFilename)
      
      0 <= (splitIndex = @splits.indexOf(fileIndex))
    
    open: (indexOrFilename, options = {}) ->
      [fileIndex, file] = @$resolveFile(indexOrFilename)
      
      # Figure out in which split to open the file
      if options.split is true then splitIndex = @splits.length
      else if angular.isNumber(options.split) then splitIndex = Math.max(0, Math.min(@splits.length, parseInt(options.split, 10)))
      else splitIndex = @activeSplitIndex
      
      # We need to create a new split
      if splitIndex is @splits.length then @splits.push(fileIndex)

  
  return service
]