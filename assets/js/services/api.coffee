window._ = require("lodash")

require "../../vendor/restangular/restangular.js"

require "../services/url.coffee"
require "../services/visitor.coffee"


module = angular.module "plunker.service.api", [
  "restangular"

  "plunker.service.url"
  "plunker.service.visitor"
]

module.factory "api", ["$rootScope", "Restangular", "url", "visitor", ($rootScope, Restangular, url, visitor) ->
  Restangular.setBaseUrl url.api
  Restangular.setDefaultRequestParams sessid: visitor.session.id

  $rootScope.$watch ( -> visitor.session.id ), (sessId) ->
    Restangular.setDefaultRequestParams sessid: sessId
  
  Restangular
]