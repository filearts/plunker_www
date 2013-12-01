dominatrix = require "../../vendor/dominatrix/dominatrix"
semver = require "semver"
_ = require "lodash"

require "../services/api.coffee"


module = angular.module "plunker.service.htmlFile", [
  "plunker.service.api"
]

module.factory "htmlFile", ["$q", "api", ($q, api) ->
  
  class HtmlFile
    constructor: (markup) ->
      @doc = window.document.implementation.createHTMLDocument("")
      @write markup if markup
    
    write: (markup = "<!doctype html>") =>
      @doc.open()
      @doc.write(@originalMarkup = markup)
      @doc.close()
      
      @dependencies = []
      @packages = {}
      
      $q.when(@)
    
    findDeclaredDependencies: =>
      elements = @doc.querySelectorAll("script[data-require], link[data-require]")
      
      for el in elements
        $el = angular.element(el)
        type = if el.nodeName.toLowerCase() is "script" then "scripts" else "styles"
        
        if reqRef = @parsePackageRef($el.attr("data-require"))
          pkg = @getDependency reqRef.name,
            range: reqRef.range
            textRange: reqRef.textRange
            version: @parseSemver($el.attr("data-semver"))
          
          pkg[type].push(el)
      
      $q.when(@)
      
    addDependency: (pkgRef) ->
      pkgRef = @parsePackageRef(pkgRef)
      
      @loadPackageDefinition(pkgRef.name, pkgRef.range)
      
    getDependency: (pkgName, options = {}) ->
      options.textRange ||= "*"
      options.range ||= new semver.Range(options.textRange)
      
      unless @packages[pkgName]
        @packages[pkgName] =
          name: pkgName
          range: options.range
          textRange: options.textRange
          currentVersion: options.version
          matchingVersions: []
          scripts: []
          styles: []
          children: []
          parents: []
          loaded: null
        
        #@dependencies.push @packages[pkgName]
        
      @packages[pkgName]
    
    loadVersionsForPackage: (pkgName, pkgRange = new semver.Range("*")) ->
      pkgInst = @getDependency(pkgName)
      
      pkgInst.loaded ||= api.all("catalogue").all("packages").one(pkgName).get().then (pkgDef) ->
        pkgInst.versions = pkgDef.versions.sort (a, b) -> semver.rcompare(a.semver, b.semver)

      pkgInst.loaded.then (versions) ->
        _.filter versions, (verDef) -> pkgRange.test(verDef.semver)
    
    loadPackageDependencies: (parent, verDef = parent.matchingVersions[0]) ->
      file = @
      promises = []
      
      _.each verDef.dependencies, (depObj) ->
        if depRef = file.parsePackageRef("#{depObj.name}@#{depObj.range or '*'}")
        
          promises.push file.loadPackageDefinition(depRef.name, depRef.range).then (pkgInst) ->
            #pkgInst = file.getDependency(depRef.name, depRef)
            pkgInst.parents.push(parent)
            
            parent.children.push(pkgInst)
            
            pkgInst

      $q.all(promises).then -> parent
    
    loadPackageDefinition: (pkgName, pkgRange) ->
      pkgInst = @getDependency(pkgName, pkgRange)
      file = @
      
      file.loadVersionsForPackage(pkgName, pkgRange).then (versions) ->
        return $q.reject("No matching versions found for #{pkgName}@#{pkgRange}") unless versions.length
        
        pkgInst.matchingVersions = versions
        
        if pkgInst.matchingVersions.length
        
          file.loadPackageDependencies(pkgInst, pkgInst.matchingVersions[0]).then ->
            if 0 > file.dependencies.indexOf(pkgInst)
              insertIndex = file.dependencies.length
              
              for parent in pkgInst.parents
                unless 0 > minIndex = file.dependencies.indexOf(parent)
                  insertIndex = Math.min(insertIndex, minIndex)
          
              file.dependencies.splice insertIndex, 0, pkgInst
            
            return pkgInst
        
        else
          return pkgInst
    
    createScriptTags: (pkgInst, version = pkgInst.matchingVersions[0]) ->
      tags = []
      
      if version?.scripts
        for url in version.scripts
          el = @doc.createElement("script")
          el.setAttribute("data-require", "#{pkgInst.name}@#{pkgInst.textRange}")
          el.setAttribute("data-semver", version.semver)
          el.setAttribute("src", url)
          
          tags.push el
      
      tags
        
    createStyleTags: (pkgInst, version = pkgInst.matchingVersions[0]) ->
      tags = []
      
      if version?.styles
        for url in version.styles
          el = @doc.createElement("link")
          el.setAttribute("data-require", "#{pkgInst.name}@#{pkgInst.textRange}")
          el.setAttribute("data-semver", version.semver)
          el.setAttribute("rel", "stylesheet")
          el.setAttribute("href", url)
          
          tags.push el
      
      tags
    
    toString: => dominatrix.domToHtml(@doc)
    
    updatePackageTags: (pkgInst) ->
      insertAllBefore = (before, els) ->
        if parentNode = before.parentNode
          parentNode.insertBefore el, before for el in els
      insertAllAfter = (after, els) ->
        if (nextSibling = after.nextSibling) and (parentNode = after.parentNode)
          parentNode.insertBefore el, nextSibling for el in els

      
      newScripts = @createScriptTags(pkgInst)
      newStyles = @createStyleTags(pkgInst)

      scriptsInserted = false
      stylesInserted = false
      
      if newScripts.length
        for parent in pkgInst.parents
          if parent.scripts.length
            # Insert before
            insertAllBefore parent.scripts[0], newScripts
            scriptsInserted = true
            
            # We've inserted the new scripts so we can get rid of the old ones
            angular.element(pkgInst.scripts).remove()
            
            break
        
        unless scriptsInserted
          for child in pkgInst.children
            if child.scripts.length
              insertAllAfter child.scripts[child.scripts.length - 1], newScripts
              scriptsInserted = true
            
              # We've inserted the new scripts so we can get rid of the old ones
              angular.element(pkgInst.scripts).remove()
              
              break
        
        unless scriptsInserted
          if pkgInst.scripts.length
            angular.element(pkgInst.scripts).replaceWith(newScripts)

          else if (scripts = @doc.querySelectorAll("head script")).length
            insertAllBefore scripts[0], newScripts
          else
            # Scripts not yet inserted because no parents, append to head
            angular.element(@doc.getElementsByTagName('head')).append(newScripts)

        pkgInst.scripts = newScripts
        
      
      # There are new styles
      if newStyles.length
        for parent in pkgInst.parents
          if parent.styles.length
            # Insert before
            insertAllBefore parent.styles[0], newStyles
            stylesInserted = true

            # We've inserted the new scripts so we can get rid of the old ones
            angular.element(pkgInst.styles).remove()            
            
            break
        
        unless stylesInserted
          for child in pkgInst.children
            if child.styles.length
              # Insert before
              insertAllAfter child.styles[child.styles.length - 1], newStyles
              stylesInserted = true
  
              # We've inserted the new scripts so we can get rid of the old ones
              angular.element(pkgInst.styles).remove()            
              
              break
          
        unless stylesInserted
          if pkgInst.styles.length
            angular.element(pkgInst.styles).replaceWith(newStyles)
            
          else if (styles = @doc.querySelectorAll("head link[rel=stylesheet]")).length
            insertAllBefore styles[0], newStyles
          else
            # Scripts not yet inserted because no parents, append to head
            angular.element(@doc.getElementsByTagName('head')).append(newStyles)

        pkgInst.styles = newStyles
    
    updateAllPackageTags: =>
      # Loop through the dependencies that are pre-ordered
      @updatePackageTags(pkgInst) for pkgInst in @dependencies.reverse()

      $q.when(@)

            
    loadPackageDefinitions: =>
      file = @
      promises = []
      
      _.each @packages, (pkgInst, pkgName) ->
        promises.push file.loadPackageDefinition(pkgName, pkgInst.range)
      
      $q.all(promises).then -> file.packages

    parsePackageRef: (pkgRef) -> (parts = pkgRef.split("@")) and {name: parts.shift(), textRange: parts.join("@"), range: @parseRange(parts.join("@"))}
    parseSemver: (semver = "0.0.0") -> try new semver.Semver(semver)
    parseRange: (range = "*") -> try new semver.Range(range)
  
  create: (markup) -> new HtmlFile(markup)
]