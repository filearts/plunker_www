dominatrix = require "../../vendor/dominatrix/dominatrix"


module = angular.module "plunker.service.htmlFile", [
]

module.factory "htmlFile", [ "$q", ($q) ->
  class HtmlFile
    constructor: (@markup) ->
      @doc = window.document.implementation.createHTMLDocument("")
      @doc.open()
      @doc.write(@markup)
    
    toString: -> dominatrix.domToHtml(@doc)
  
  parse: (markup) -> new HtmlFile(markup)
  update: (markup) ->
    dfd = $q.defer()
    
    dfd.resolve(@parse(markup).toString())
    
    dfd.promise
]