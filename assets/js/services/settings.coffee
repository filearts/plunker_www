module = angular.module "plunker.settings", []

module.service "settings", [ () ->
  previewer:
    delay: 400
  editor:
    tab_size: 2
    soft_tabs: true
    theme: "textmate"
]