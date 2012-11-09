module = angular.module "plunker.url", []

module.service "url", ->
  api: "http://api.plnkr.co"
  embed: "http://embed.plnkr.co"
  run: "http://run.plnkr.co"
  www: "http://plnkr.co"
