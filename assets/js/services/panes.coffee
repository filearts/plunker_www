module = angular.module "plunker.panes", [
]

module.service "panes", [ "$rootScope", "$location", ($rootScope, $location) ->
  new class Panes
    constructor: ->
      @panes = []
      @active = null
      
      panes = @
    
      # Handle changes to the URL
      $rootScope.$watch ( -> $location.search().p ), (paneId) ->
        if paneId
          if pane = panes.findById(paneId) then panes.open(pane)
          else
            search = $location.search()
            delete search.p
            $location.search(search).replace()
        else
          if (search = $location.search()).p
            delete search.p
            $location.search(search).replace()

    findById: (paneId) ->
      return pane for pane in @panes when pane.id is paneId

    add: (pane) ->
      throw new Error("All panes must have an id attribute") unless pane.id
      
      pane.title ||= "Activate this pane"
      pane.class ||= ""
      pane.icon ||= "check-empty"
      pane.link ||= angular.noop
      pane.template ||= ""
      
      @panes.push(pane)
      
    remove: (pane) ->
      if (idx = @panes.indexOf(pane)) >= 0
        delete @panes[pane.id]
    
    open: (@active) ->
      if $location.search().p != @active.id
        search = $location.search()
        search.p = @active.id
        
        $location.search(search).replace()
    close: (pane) ->
      @active = null
      
      if $location.search().p
        search = $location.search()
        delete search.p
        
        $location.search(search).replace()

    toggle: (pane) ->
      if @active is pane then @close(pane)
      else @open(pane)
]