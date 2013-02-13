module = angular.module "plunker.activity", []

module.value "activity", do ->
  $$emit = (arr, type, event) -> fn.call(this, type, event) for fn in arr if arr
  $$register = (arr, handler) ->
    arr.push(handler)
    -> if 0 <= idx = arr.indexOf(handler) then arr.splice(idx, 1)
    
  $$guard = false
  
  class Client
    constructor: (@server, @name) ->
      @watchers = []
      @handlers = []
    
    record: (type, event) -> @server.emitEvent(@, type, event) unless $$guard
    playback: (type, event) ->
      $$guard = true
      @server.emitAction(@, type, event)
      $$guard = false
      
    watch: (watcher) -> $$register(@watchers, watcher)
    handle: (handler) -> $$register(@handlers, handler)
    
    watchEvent: (eventType, handler) ->
      @watch (type, event) ->
        if type is eventType then handler(type, event)
    
    handleEvent: (eventType, handler) ->
      @handle (type, event) ->
        if type is eventType then handler(type, event)
  
  new class Server
    constructor: ->
      @clients = {}
    
    # Create or return an existing client
    client: (name) -> @clients[name] ||= new Client(@, name)
  
    emitAction: (emitter, type, event) ->
      for name, client of @clients when name != emitter.name
        $$emit(client.handlers, type, event)
  
    emitEvent: (emitter, type, event) ->
      for name, client of @clients when name != emitter.name
        $$emit(client.watchers, type, event)
        
        
  ###
  $$handlers = {}
  $$watchers = []
  
  $$register = (arr, fn) ->
    arr.push(fn)
    -> if (idx = arr.indexOf(fn)) >= 0 then arr.splice(idx, 1)
  
  $$emit = (arr, args) ->
    fn.apply(this, args) for fn in arr if arr

  new class Activity
    record: (args...) -> $$emit($$watchers, args)
    play: (event, args...) -> $$emit($$handlers[event], args)
    
    addWatcher: (fn) -> $$register($$watchers, fn)
    addHandler: (event, fn) -> $$register($$handlers[event] ?= [], fn)
  ###