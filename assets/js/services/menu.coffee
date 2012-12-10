module = angular.module("plunker.menu", [])

module.service "menu", [ () ->
  menu =
    items: []
    active: null
    
  menu.addItem = (name, item) ->
    item.id = name
    menu.items.push item
  
  menu.activate = (name) ->
    menu.active = item for item in @items when item.id == name
  
  menu.deactivate = ->
    menu.active = null
    
  menu
]