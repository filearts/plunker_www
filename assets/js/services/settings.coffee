module = angular.module "plunker.settings", []

module.service "settings", [ () ->
  
  settings =
    previewer:
      delay: 400
      auto_refresh: true
    editor:
      tab_size: 2
      soft_tabs: true
      theme: "textmate"
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
  
  angular.extend settings, saved
  
]