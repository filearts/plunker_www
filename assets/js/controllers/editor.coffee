#= require ../services/menu

module = angular.module "plunker.editorPage", [
  "plunker.menu"
]

module.run ["menu", (menu) ->
  menu.addItem "editor",
    title: "Launch the Editor"
    href: "/edit/"
    'class': "icon-edit"
    text: "Editor"
]