dominatrix = require("../../vendor/dominatrix/dominatrix")
_ = require "lodash"

require "../services/api.coffee"

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


module = angular.module "plunker.service.importer", [
  "plunker.service.api"
]

module.service "importer", [ "$q", "$http", "api", "notifier", ($q, $http, api, notifier) ->
  import: (source) ->

    if matches = source.match(templateRegex)
      api.all("plunks").one(matches[1]).get().then (plunk) ->
        plunk.files = _.values(plunk.files)
        plunk
      , (error) ->
        deferred.reject("Plunk not found")
        
    else if matches = source.match(githubRegex)
      request = $http.jsonp("https://api.github.com/gists/#{matches[1]}?callback=JSON_CALLBACK")
      
      parser = request.then (response) ->
        if response.data.meta.status >= 400 then return $q.reject("Gist not found")
        
        gist = response.data.data
        json = 
          'private': true
          files: []
        
        if manifest = gist.files["plunker.json"]
          try
            angular.extend json, angular.fromJson(manifest.content)
          catch e
            return $q.reject("Unable to parse the plunker.json file")

        json.description = gist.description or "https://gist.github.com/#{$stateParams.gistId}"

        for filename, file of gist.files
          unless filename == "plunker.json"
            json.files.push
              filename: filename
              content: file.content 
        
        return json
      ###else if matches = source.match(fiddleRegex)
      fiddleRef = matches[1] + if matches[2] then "/#{matches[2]}" else ""
      fiddleUrl = "http://jsfiddle.net/#{fiddleRef}/show"
      
      request = $http.jsonp("http://query.yahooapis.com/v1/public/yql?q=SELECT * FROM html WHERE url=\"#{fiddleUrl}\" AND xpath=\"/html\" and compat=\"html5\"&format=xml&callback=JSON_CALLBACK")
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
      ###
    else return $q.reject("Not a recognized source")
]