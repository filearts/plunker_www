module = angular.module("plunker.menu", [])

module.service "menu", [ () ->
  menu =
    items: {}
    active: null
    
  menu.addItem = (name, item) ->
    menu.items[name] = item
  
  menu.activate = (name) ->
    menu.active = item if item = menu.items[name]
    
  menu
]