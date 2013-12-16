module = angular.module "plunker.settings", []

module.service "settings", [ () ->
  
  settings =
    previewer:
      delay: 1000
      auto_refresh: true
    editor:
      tab_size: 2
      font_size: 12
      soft_tabs: true
      theme: "textmate"
      keyboard_handler: "ace"
      wrap:
        range:
          min: 0
          max: 80
        enabled: false
        
  
  
  if localStorage?
    if saved = localStorage.getItem("plnkr_settings")
      try
        saved = JSON.parse(saved)
      catch e
        saved = {}
      
    setInterval ->
      localStorage.setItem "plnkr_settings", JSON.stringify(settings)
    , 2000
  
  setSaved = (parent, saved) ->
    for key, val of saved
      if angular.isObject(val)
        if angular.isObject(parent[key]) then setSaved(parent[key], val)
        else parent[key] = saved
      else
        parent[key] = val
    parent
  
  setSaved settings, saved
  
]