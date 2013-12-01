fs = require "fs"


module = angular.module "plunker"

module.run ["$templateCache", ($templateCache) ->
  $templateCache.put "/partials/panes/templates.html", fs.readFileSync(__dirname + "/../../public/partials/panes/templates.html")
  $templateCache.put "/partials/panes/toolbar.html", fs.readFileSync(__dirname + "/../../public/partials/panes/toolbar.html")
  $templateCache.put "/partials/panes/sidebar.html", fs.readFileSync(__dirname + "/../../public/partials/panes/sidebar.html")
  $templateCache.put "/partials/panes/paneselector.html", fs.readFileSync(__dirname + "/../../public/partials/panes/paneselector.html")
  $templateCache.put "/partials/editor.html", fs.readFileSync(__dirname + "/../../public/partials/editor.html")
  $templateCache.put "/partials/card.html", fs.readFileSync(__dirname + "/../../public/partials/card.html")
] 