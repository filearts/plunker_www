#= require dominatrix

#= require ./../services/plunks
#= require ./../services/updater
#= require ./../services/notifier

# Use the identifier {{VERSION}} which will be substituted with the example's stated version
NGDOC_BASE_URL = "https://code.angularjs.org/{{VERSION}}/docs/examples/"

plunkerRegex = ///
  ^
    \s*                   # Leading whitespace
    (?:plunk:)?           # Optional plunk:prefix
    ([-\._a-zA-Z0-9]+)     # Plunk ID
    \s*                   # Trailing whitespace
  $
///i

templateRegex = ///
  ^
    \s*                   # Leading whitespace
    tpl:                  # Optional plunk:prefix
    ([-\._a-zA-Z0-9]+)    # Plunk ID
    \s*                   # Trailing whitespace
  $
///i

fiddleRegex = ///
  ^
    \s*                   # Leading whitespace
    fiddle:               # Optional plunk:prefix
    ([-\._a-zA-Z0-9]+)    # Fiddle ID
    (?:@([0-9]*))?        # Fiddle version
    \s*                   # Trailing whitespace
  $
///i

githubRegex = ///
  ^
    \s*                   # Leading whitespace
    (?:                   # Optional protocol/hostname
      (?:https?\://)?     # Protocol
      gist\.github\.com/  # Hostname
    |
      gist\:
    )
    ([0-9]+|[0-9a-z]{20}) # Gist ID
    (?:#.+)?              # Optional anchor
    \s*                   # Trailing whitespace
  $
///i

ngdocRegex = ///
  ^
    \s*                   # Leading whitespace
    ngdoc:                # Angular documentation prefix
    ([^\/@]+)              # Example name
    (?:@([^\/]+))?        # Optional example version
    \s*                   # Trailing whitespace
  $
///i

manifestRegex = ///
  ^
    \s*                   # Leading whitespace
    manifest:             # Angular documentation prefix
    (.+)                  # Example name
    \s*                   # Trailing whitespace
  $
///i


module = angular.module "plunker.importer", [
  "plunker.plunks"
  "plunker.updater"
  "plunker.notifier"
]

module.service "importer", [ "$q", "$http", "plunks", "updater", "notifier", ($q, $http, plunks, updater, notifier) ->
  import: (source) ->
    deferred = $q.defer()
    
    if matches = source.match(templateRegex)
      plunks.findOrCreate(id: matches[1]).refresh().then (plunk) ->
        files = {}
        files[filename] = {filename: filename, content: file.content} for filename, file of plunk.files
        
        finalize = ->
          deferred.resolve
            description: plunk.description
            tags: angular.copy(plunk.tags)
            files: files
            source: source
        
        if index = files['index.html']
          markup = updater.parse(index.content)
          markup.updateAll().then ->
            index.content = markup.toHtml()
            
            finalize()
        else finalize()
        
      , (error) ->
        deferred.reject("Plunk not found")
        
    else if matches = source.match(plunkerRegex)
      plunks.findOrCreate(id: matches[1]).refresh().then (plunk) ->
        files = {}
        files[filename] = {filename: filename, content: file.content} for filename, file of plunk.files
        
        
        deferred.resolve
          description: plunk.description
          tags: angular.copy(plunk.tags)
          files: files
          plunk: angular.copy(plunk)
      , (error) ->
        deferred.reject("Plunk not found")
        
    else if matches = source.match(githubRegex)
      request = $http.jsonp("https://api.github.com/gists/#{matches[1]}?callback=JSON_CALLBACK")
      
      request.then (response) ->
        if response.data.meta.status >= 400 then deferred.reject("Gist not found")
        else
          gist = response.data.data
          json = 
            'private': true
          
          if manifest = gist.files["plunker.json"]
            try
              angular.extend json, angular.fromJson(manifest.content)
            catch e
              console.error "Unable to parse manifest file:", e

  
          angular.extend json,
            source:
              type: "gist"
              url: gist.html_url
              title: "gist:#{gist.id}"
            files: {}
          
          json.description = json.source.description = gist.description if gist.description

          for filename, file of gist.files
            unless filename == "plunker.json"
              json.files[filename] =
                filename: filename
                content: file.content 
          
          if index = json.files['index.html']
            markup = updater.parse(index.content)
            markup.updateAll().then ->
              index.content = markup.toHtml()
              
              deferred.resolve(json)
            , (err) ->
              notifier.error "Auto-update failed", err.message
              deferred.resolve(json)
          else deferred.resolve(json)

    else if matches = source.match(ngdocRegex)
      exampleId = matches[1]
      exampleVersion = matches[2]
      
      manifestUrl = NGDOC_BASE_URL.replace("{{VERSION}}", exampleVersion or "") + exampleId + "/manifest.json"
      
      manifestRequest = $http.get(manifestUrl).then (manifestResponse) ->
        if manifestResponse.status >= 400 then deferred.reject("Unable to load the specified example's manifest")
        else
          # Array of promises to fetch each file in the example
          promises = []
          json =
            description: "Angular documentation example: #{manifestResponse.data.name}"
            tags: ["angularjs"]
            files: {}
          
          for filename in manifestResponse.data.files then do (filename) ->
            fileUrl = NGDOC_BASE_URL.replace("{{VERSION}}", exampleVersion or "") + exampleId + "/" + filename
            if filename is "index-production.html" then filename = "index.html"
            promises.push $http.get(fileUrl).then (fileResponse) ->
              if fileResponse.status >= 400 then $q.reject("Unable to load the example's file: #{filename}")
              else
                json.files[filename] =
                  filename: filename
                  content: fileResponse.data
            
          $q.all(promises).then ->
            deferred.resolve(json)
      , (err) -> deferred.reject("Unable to load the specified example's manifest")
          
    else if matches = source.match(manifestRegex)
      console.log("matched manifest", matches)
      manifestUrl = matches[1]
      baseUrl = manifestUrl.split("/").pop()
      baseUrl = baseUrl.join("/")
      
      manifestRequest = $http.get(manifestUrl).then (manifestResponse) ->
        if manifestResponse.status >= 400 then deferred.reject("Unable to load the specified example's manifest")
        else
          # Array of promises to fetch each file in the example
          promises = []
          json =
            description: manifestResponse.data.name or manifestUrl
            tags: manifestResponse.data.tags or []
            files: {}
          
          for filename in manifestResponse.data.files then do (filename) ->
            fileUrl = baseUrl + "/" + filename
            if filename is "index-production.html" then filename = "index.html"
            promises.push $http.get(fileUrl).then (fileResponse) ->
              if fileResponse.status >= 400 then $q.reject("Unable to load the example's file: #{filename}")
              else
                json.files[filename] =
                  filename: filename
                  content: fileResponse.data
            
          $q.all(promises).then ->
            deferred.resolve(json)
      , (err) -> deferred.reject("Unable to load the specified example's manifest")
          
    else if matches = source.match(fiddleRegex)
      fiddleRef = matches[1] + if matches[2] then "/#{matches[2]}" else ""
      fiddleUrl = "http://jsfiddle.net/#{fiddleRef}/show"
      
      request = $http.jsonp("https://query.yahooapis.com/v1/public/yql?q=SELECT * FROM html WHERE url=\"#{fiddleUrl}\" AND xpath=\"/html\" and compat=\"html5\"&format=xml&callback=JSON_CALLBACK")
      request.then (response) ->
        if response.status >= 400 then deferred.reject("Failed to fetch fiddle")
        else
          unless fiddleHtml = response.data.results[0]
            return deferred.reject("Failed to fetch fiddle")
          
          fiddleHtml = fiddleHtml.replace(/<script([^>]*)\/>/ig, "<script$1></script>")
          fiddleHtml = fiddleHtml.replace(/(?:\/\/)?<!\[CDATA\[/g, "").replace(/(?:\/\/)?\]\]>/g, "").replace(/(?:\/\/)?\]\]>/g, "")
          
          doc = window.document.implementation.createHTMLDocument("")
          doc.open()
          doc.write(fiddleHtml)
          doc.innerHTML = fiddleHtml
          
          json = 
            'private': true
          
          angular.extend json,
            source:
              type: "fiddle"
              url: fiddleUrl
              title: $("title", doc).text()
            files: {}
          
          json.description = $("title", doc).text()
          
          $("link[href]", doc).each ->
            href = $(@).attr("href")
            
            $(@).attr "href", "http://jsfiddle.net#{href}" if href.charAt(0) is "/" and href.charAt(1) isnt "/"

          $("script[src]", doc).each ->
            href = $(@).attr("src")
            
            $(@).attr "src", "http://jsfiddle.net#{href}" if href.charAt(0) is "/" and href.charAt(1) isnt "/"
          
          if ($script = $("head script:not([src])", doc)).length
          
            if script = jQuery.trim($script.text())
              json.files["script.js"] = 
                filename: "script.js"
                content: script
              $script.text("").attr("src", "script.js")
            else $script.remove()
  
          if ($style = $("head style", doc)).length
            if style = jQuery.trim($style.text())
              json.files["style.css"] =
                filename: "style.css"
                content: style
              $style.replaceWith('<link rel="stylesheet" href="style.css">')
            else $style.remove()
          
          serializer = new XMLSerializer()
          json.files["index.html"] = index =
            filename: "index.html"
            content: dominatrix.domToHtml(doc)
          
          markup = updater.parse(index.content)
          markup.updateAll().then ->
            index.content = markup.toHtml()
            
            deferred.resolve(json)
          , (err) ->
            notifier.error "Auto-update failed", err.message
            deferred.resolve(json)
    else return $q.reject("Not a recognized source")
          
    deferred.promise
]