#= require js-beautify/beautify
#= require js-beautify/beautify-html
#= require js-beautify/beautify-css

#= require ./../services/session
#= require ./../services/activity
#= require ./../services/settings 


module = angular.module "plunker.beautifier", [
  "plunker.session"
]

module.service "beautifier", [ "$rootScope", "session", "activity", "settings", ($rootScope, session, activity, settings) ->
  client = activity.client("beautifier")
  
  isBeautifiable: -> !!session.activeBuffer.filename.match /\.(html|css|js)$/
  beautify: ->
    filename = session.activeBuffer.filename
    source = session.activeBuffer.content
    
    beautyFunc = 
      if filename.match /\.html$/ then html_beautify
      else if filename.match /\.css/ then css_beautify
      else if filename.match /\.js/ then js_beautify
    
    if beautyFunc
      options = 
        indent_size: settings.editor.tab_size
        indent_char: " "
        indent_with_tab: !settings.editor.soft_tabs
      
      beautified = beautyFunc(source, options)
      
      client.playback "remove",
        buffId: session.activeBuffer.id
        offset: 0
        text: source
      client.playback "insert",
        buffId: session.activeBuffer.id
        offset: 0
        text: beautified
]