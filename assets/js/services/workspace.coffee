require "../services/project.coffee"
require "../services/session.coffee"


module = angular.module "plunker.service.workspace", [
  "plunker.service.project"
  "plunker.service.session"
  "plunker.service.layout"
]


# Service representing the state of the plunker editor interface
#
# 
module.factory "workspace", [ "project", "session", "layout", (project, session, layout) ->
  client = session.createClient("Workspace")
                             
  service = new class Workspace
    constructor: ->
      @splits = []
      @activeSplitIndex = 0
      @activeFileIndex = 0
      
      @reset()
      @$setupListeners()
    
    $resolveFile: (indexOrFilename) ->
      fileIndex =
        if angular.isNumber(indexOrFilename) then indexOrFilename
        else project.getIndexByFilename(indexOrFilename)
  
      file = project.getFileByIndex(fileIndex)
      
      # Return a tuple of (fileIndex, file)
      return [fileIndex, file]
    
    $setupListeners: ->
      client.on "cursorSetFile", (e, snapshot) ->
        if 0 > splitIndex = service.getSplitIndexByFileIndex(e.index)
          splitIndex = service.activeSplitIndex
        
        service.open e.index, split: splitIndex
      
      client.on "cursorSetOffset", (e, snapshot) ->
        #TODO
      
      client.on "fileRemove", (e, snapshot) ->
        service.close(e.index)

      client.on "reset", (e, snapshot) ->
        service.reset()
    
    # Get the index of the active pane
    getActiveSplitIndex: -> @activeSplitIndex
    
    # Get the index of the active split
    getActiveFileIndex: -> @activeFileIndex
    
    # Return an array of open splits with their corresponding file indices
    getActiveSplitIndices: -> @splits
    
    getFileIndexBySplitIndex: (splitIndex) -> @splits[splitIndex]
    
    getSplitIndexByFileIndex: (fileIndex) -> @splits.indexOf(fileIndex)
    getSplitCount: -> @splits.length
    getSplits: -> @splits
    
    isFileOpen: (indexOrFilename, options = {}) ->
      [fileIndex, file] = @$resolveFile(indexOrFilename)
      
      0 <= (splitIndex = @splits.indexOf(fileIndex))
    
    close: (indexOrFilename, options = {}) ->
      [fileIndex, file] = @$resolveFile(indexOrFilename)
      
      unless 0 > splitIndex = @getSplitIndexByFileIndex(fileIndex)
        if @splits.length > 1
          @splits.splice splitIndex, 1
          @activeSplitIndex-- if @activeSplitIndex is splitIndex
          @activeFileIndex = @splits[@activeSplitIndex]
        else
          debugger
          @open(0)
    
    open: (indexOrFilename, options = {}) ->
      [fileIndex, file] = @$resolveFile(indexOrFilename)
      
      # Figure out in which split to open the file
      if 0 > splitIndex = @getSplitIndexByFileIndex(fileIndex) 
        if options.split is true then splitIndex = @splits.length
        else if angular.isNumber(options.split) then splitIndex = Math.max(0, Math.min(@splits.length, parseInt(options.split, 10)))
        else splitIndex = @activeSplitIndex
      
      # We need to create a new split
      if splitIndex == @splits.length then @splits.push(fileIndex)
      
      @splits[@activeSplitIndex = splitIndex] = @activeFileIndex = fileIndex

    openNext: ->
      @open (@activeFileIndex + 1) % project.getFileCount()

    openPrev: ->
      @open (@activeFileIndex + project.getFileCount() - 1) % project.getFileCount()

    reset: ->
      @splits.length = 1
      @splits[0] = 0
      @activeSplitIndex = 0
      @activeFileIndex = 0

    togglePane: (paneName) -> layout.toggle(paneName)
    paneOpen: (paneName) -> layout.open(paneName)
    paneClose: (paneName) -> layout.close(paneName)
  return service
]