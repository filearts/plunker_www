require "../services/session.coffee"


module = angular.module "plunker.service.splitter", [
  "plunker.service.session"
]

module.factory "splitter", ["session", (session) ->
  client = session.createClient("splitter")

  active: 0
  splits: 1
  indices: []
  focus: (@active) ->
  split: (filename) ->
    @splits++
    if filename
      @active = @splits - 1
      client.cursorSetFile(filename)
    @splits
  join: -> @splits--
  isSplit: -> @splits > 1
  close: (idx) ->
    throw new Error("Unable to eliminate all splits") if @splits <= 1
    wasActive = idx is @active
    
    @active-- if @active >= idx
    @indices.splice idx, 1
    @splits = @indices.length
    @active = Math.max(0, @active)
    
    #client.cursorSetIndex(@indices[@active]) if wasActive
    
  isFilenameOpen: (filename) -> @getSplitForFilename(filename) != null
  getSplitForFilename: (filename) ->
    snapshot = client.getSnapshot()
    split = null
    index = null
    index = idx for file, idx in snapshot.files when file.filename is filename
    
    if index != null
      found = @indices.indexOf(index)
      
      split = found unless found < 0
    
    return split
]