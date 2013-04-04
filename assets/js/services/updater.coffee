#= require ./../../vendor/js-beautify/beautify-css
#= require ./../../vendor/js-beautify/beautify
#= require ./../../vendor/js-beautify/beautify-html

#= require ./../../vendor/semver/semver

#= require ./../services/catalogue
#= require ./../services/settings
#= require ./../services/notifier


module = angular.module "plunker.updater", [
  "plunker.catalogue"
  "plunker.settings"
  "plunker.notifier"
]

module.service "updater", [ "$q", "catalogue", "settings", "notifier", ($q, catalogue, settings, notifier) ->
  class PackageRef
    constructor: (pkgRef) ->
      [@name, @range] = pkgRef.split("@")
      
      @range ||= "*"
      
    toString: -> "#{@name}@#{range}"
    
    fetch: -> catalogue.findOrCreate(name: @name).refresh()
  
  update: (markup) ->
    promises = []
    dfd = $q.defer()
    
    doc = window.document.implementation.createHTMLDocument("")
    doc.open()
    doc.write(markup)
    #doc.close()
    
    $head = $("head", doc)
    
    dependencies = {}
    
    $("script[data-require], link[data-require]", doc).each (el) ->
      required = $(@).data("require")
      
      dependencies[required] ||=
        ref: new PackageRef(required)
        scripts: []
        styles: []
      
      type = if @nodeName.toLowerCase() is "script" then "scripts" else "styles"
      
      dependencies[required][type].push $(@)
    
    for required, dependency of dependencies then do (required, dependency) ->
      dfd = $q.defer()
      
      promises.push dependency.ref.fetch().then (pkg) ->
        unless verDef = pkg.getLatestVersion(dependency.ref.range)
          return notifier.error("No matching versions for: #{required}")
        
        while dependency.scripts.length > verDef.scripts.length
          $el = dependency.scripts.pop()
          $el.remove()
        
        while dependency.styles.length > verDef.styles.length
          $el = dependency.styles.pop()
          $el.remove()
          
        for url, idx in verDef.scripts
          unless $el = dependency.scripts[idx]
            $prev = $last or $head.children().last()
            
            el = document.createElement("script")
            el.setAttribute("data-require", required)
            el.setAttribute("data-package", "#{dependency.ref.name}@#{verDef.semver}")
            el.setAttribute("src", url)
            
            $prev[0].parentNode.insertBefore(el, $prev[0].nextSibling)
          else
            $el.attr "src", url
            $el.attr "data-package", "#{dependency.ref.name}@#{verDef.semver}"
          
          $last = $el
        
        for url, idx in verDef.styles
          unless $el = dependency.scripts[idx]
            $prev = $last or $head.children().last()
            
            el = document.createElement("link")
            el.setAttribute("data-require", required)
            el.setAttribute("data-package", "#{dependency.ref.name}@#{verDef.semver}")
            el.setAttribute("rel", "stylesheet")
            el.setAttribute("href", url)
            
            $prev[0].parentNode.insertBefore(el, $prev[0].nextSibling)
          else
            $el.attr "href", url
            $el.attr "data-package", "#{dependency.ref.name}@#{verDef.semver}"
          
          $last = $el
        
      , (err) -> notifier.error("Unable to load dependency: #{dependency.ref.name}")
        
    
    $q.all(promises).then ->
      serializer = new XMLSerializer()
      doc.close()
      html = serializer.serializeToString(doc)
      doc = null
      
      style_html(html, indent_size: settings.editor.tab_size)
    , ->
      doc.close()
      doc = null
]