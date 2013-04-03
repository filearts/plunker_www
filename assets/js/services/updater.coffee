#= require ./../../vendor/js-beautify/beautify-css
#= require ./../../vendor/js-beautify/beautify
#= require ./../../vendor/js-beautify/beautify-html

#= require ./../../vendor/semver/semver

#= require ./../services/catalogue
#= require ./../services/settings


module = angular.module "plunker.updater", [
  "plunker.catalogue"
  "plunker.settings"
]

module.service "updater", [ "$q", "catalogue", "settings", ($q, catalogue, settings) ->
  class PackageRef
    constructor: (pkgRef) ->
      [@name, @range] = pkgRef.split("@")
      
      @range ||= "*"
    
    fetch: -> catalogue.findOrCreate(name: @name).refresh()
  
  update: (markup) ->
    promises = []
    dfd = $q.defer()
    
    doc = window.document.implementation.createHTMLDocument("")
    doc.open()
    doc.write(markup)
    doc.close()
    
    $("script[data-require]", doc).each (el) ->
      $el = $(@)
      dfd = $q.defer()
      ref = new PackageRef($el.data("require"))
      
      promises.push ref.fetch().then (pkg) ->
        $el.attr("src", pkg.getLatestVersion(ref.range).scripts[0])
    
    $q.all(promises).then ->
      serializer = new XMLSerializer()
      html = serializer.serializeToString(doc)
      
      style_html(html, indent_size: settings.editor.tab_size)
]