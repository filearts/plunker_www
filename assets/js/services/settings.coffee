module = angular.module "plunker.settings", []

module.service "settings", [ () ->
  previewer:
    delay: 400
    auto_refresh: true
  editor:
    tab_size: 2
    soft_tabs: true
    theme: "textmate"
]