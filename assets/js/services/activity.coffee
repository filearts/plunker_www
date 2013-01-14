module = angular.module "plunker.activity", []

module.value "activity", do ->
  $$emit = (arr, args) -> fn.apply(this, args) for fn in arr if arr
  
  ###
  class Client
    constructor: (@server, @name) ->
      @watchers = []
      @handlers = []
    
    record: (event, path, args...) -> @server.emitEvent(@, event, path, args)
    playback: (event, path, args...) -> @server.emitAction(@, event, path, args)
      
    watch: (watcher) -> @watchers.push(watcher)
    handle: (handler) -> @handlers.push(handler)
    
    handleEvent: (eventType, handler) ->
      @handle (event, path, args) ->
        if event is eventType then handler(event, path, args...)
  
  new class Server
    constructor: ->
      @clients = {}
    
    # Create or return an existing client
    client: (name) -> @clients[name] ||= new Client(@, name)
  
    emitAction: (emitter, event, path, args) ->
      for name, client of @clients when name != emitter.name
        $$emit(client.handlers, event, path, args...)
  
    emitEvent: (emitter, event, path, args) ->
      for name, client of @clients when name != emitter.name
        $$emit(client.watchers, event, path, args...)
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