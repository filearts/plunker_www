#= require ./../../vendor/dominatrix

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
      if angular.isString(pkgRef) then [@name, @range] = pkgRef.split("@")
      else if angular.isObject(pkgRef) then angular.copy(pkgRef, @)
      
      @range ||= "*"
      
    toString: -> "#{@name}@#{@range}"
    
    fetch: ->
      pkgRef = @
      
      $q.when(catalogue.findOne(name: @name)).then (pkg) ->
        pkgRef.pkg = pkg
        pkgRef.ver = pkg.getMatchingVersion(pkgRef.range)
        
        unless pkgRef.ver then $q.reject(new Error("No matching version for #{pkg.name}@#{pkgRef.range}"))
        else pkgRef

    
  class MarkupFile
    constructor: (markup) ->
      @dependencies = []
      @packages = {}
      @obsolete = []
      @current = []
      
      @doc = window.document.implementation.createHTMLDocument("")

      @parse(markup)
    
    parse: (markup) ->
      @doc.open()
      @doc.write(markup)
      @doc.documentElement?.innerHTML = markup
    
    updateOrInsert: (pkgDef, verDef) ->
      self = @
      required = "#{pkgDef.name}@#{verDef.semver}"
      
      @addRequired(required).then (entry) -> 
        self.updateEntry(entry, verDef)

    addRequired: (required, options = {}) ->
      self = @
      
      ref = new PackageRef(required)
      required = ref.toString()
      
      unless entry = promise = @packages[ref.name]
        entry = 
          currentVer: options.semver
          required: required
          ref: ref
          scripts: []
          styles: []
          dependencies: []
          children: []
          parent: options.parent
        
        if options.parent
          options.parent.children.push(entry)
          unless 0 > idx = @dependencies.indexOf(options.parent)
            @dependencies.splice(Math.max(0, idx - 1), 0, entry)
          else
            console.error "[WTF] This should not happen"
        else @dependencies.push(entry)
        
        @packages[ref.name] = entry
        
        promise = entry.ref.fetch().then (pkgRef) ->
          unless entry.currentVer == pkgRef.ver.semver then list = self.obsolete
          else list = self.current
          
          if options.parent and not (0 > idx = list.indexOf(options.parent))
            list.splice(Math.max(0, idx - 1), 0, entry)
          else list.push(entry)
            
          childPromises = []
          childPromises.push(self.addRequired(dependency, parent: entry)) for dependency in pkgRef.ver.dependencies
          
          return $q.all(childPromises).then -> entry
        , -> $q.reject(new Error("No suitable package found for #{required}"))
      
      else
        entry.ref = ref
        entry.ref.fetch()
      
      if options.el
        # Determine the type of the tag
        type = if options.el.nodeName.toLowerCase() is "script" then "scripts" else "styles"
        
        entry[type].push $(options.el)
      else if before = options.parent?.styles[0] or options.parent?.scripts[0]
        entry.before = before
      
      return $q.when(promise)
      
    findAllDependencies: ->
      @dependencies = []
      @packages = {}
      @obsolete = []
      @current = []
      
      self = @
      promises = []
      
      $("script[data-require], link[data-require]", @doc).each (el) ->
        required = $(@).data("require")
        semver = $(@).data("semver")
        promises.push self.addRequired(required, el: @, semver: semver) if required
        
      $q.all(promises)
    
    updateEntry: (entry, verDef) ->
      $head = $("head", @doc)
      markup = @
      verDef ||= entry.ref.ver
      
      while entry.scripts.length > verDef.scripts.length
        $el = entry.scripts.pop()
        $el.remove()
      
      while entry.styles.length > verDef.styles.length
        $el = entry.styles.pop()
        $el.remove()

      for url, idx in verDef.styles
        unless $el = entry.styles[idx]
          el = document.createElement("link")
          el.setAttribute("data-require", entry.required)
          el.setAttribute("data-semver", verDef.semver)
          el.setAttribute("rel", "stylesheet")
          el.setAttribute("href", url)
          
          if ($prev = $last or $head.find("link[data-require]").last()).length
            prev = $prev[0]
            prev.parentNode.insertBefore(el, prev.nextSibling) # Insert after last builder stylesheet
          else if ($prev = $head.find("style, link[rel=stylesheet], script").first()).length
            prev = $prev[0]
            prev.parentNode.insertBefore(el, prev) # Insert before first non-builder stylesheet
          else $head.append(el)
          
          entry.styles.push($el = $(el))
        else
          $el.attr "href", url
          $el.attr "data-semver", verDef.semver
        
        $last = $el
            
      for url, idx in verDef.scripts
        before = after = null
        unless $el = entry.scripts[idx]
          el = document.createElement("script")
          el.setAttribute("data-require", entry.ref.toString())
          el.setAttribute("data-semver", verDef.semver)
          el.setAttribute("src", url)
          
          if ($prev = $last or $head.find("script[data-require]").last()).length
            prev = $prev[0]
            prev.parentNode.insertBefore(el, prev.nextSibling) # Insert after last builder script
          else if ($prev = $head.find("style, link[rel=stylesheet], script").first()).length
            prev = $prev[0]
            prev.parentNode.insertBefore(el, prev) # Insert before first non-builder script
          else $head.append(el)
          
          entry.scripts.push($el = $(el))
        else
          $el.attr "src", url
          $el.attr "data-semver", verDef.semver
        
        $last = $el
      
    updateAll: ->
      markup = @
      
      @findAllDependencies().then (entries) ->
        markup.updateEntry(entry) for entry in entries

    toHtml: -> dominatrix.domToHtml(@doc)
        
  parse: (markup) -> new MarkupFile(markup)
  
]