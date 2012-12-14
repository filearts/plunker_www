#= require ../../vendor/noty/js/noty/jquery.noty
#= require ../../vendor/noty/js/noty/layouts/bottomRight
#= require ../../vendor/noty/js/noty/layouts/center
#= require ../../vendor/noty/js/noty/themes/default


module = angular.module("plunker.notifier", [])

module.factory "notifier", [ "$rootScope", ($rootScope) ->
  
  notifier = {}
  methods = ["alert", "success", "error", "warning", "information", "confirm"]
  
  notifier.prompt = (message, dflt = "", options = {}) ->
    if angular.isObject(dflt)
      options = dflt
      dflt = ""
    
    options.confirm ||= angular.noop
    options.deny ||= angular.noop
  
    if (value = window.prompt(message, dflt)) != null
      options.confirm(value)
    else
      options.deny()
  
  for method in methods then do (method) ->
    notifier[method] = (title, text, options = {}) ->
      dfd = null
      
      switch arguments.length
        when 3
          options.title = title
          options.text = text
        when 2
          if angular.isObject(text)
            options = text
            options.text = title
        when 1
          if angular.isObject(title)
            options = title
          else options.text = title
          
      options.layout ||= "bottomRight"
      options.type ||= method
      options.timeout ||= "3000"
      options.text = (if options.title then "#{options.title} - " else "") + options.text
      
      if options.type is "confirm"
        options.confirm ||= angular.noop
        options.deny ||= angular.noop
        
        angular.extend options,
          layout: "center"
          force: true
          modal: true
          animation:
            open: height: "toggle"
            close: height: "toggle"
            easing: 'swing',
            speed: 1
          buttons: [
            addClass: "btn btn-primary"
            text: "Yes"
            onClick: ($noty) ->
              $noty.close()
              $rootScope.$apply(options.confirm)
          ,
            addClass: "btn btn-danger"
            text: "No"
            onClick: ($noty) ->
              $noty.close()
              $rootScope.$apply(options.deny)
          ]

      
      noty(options)
      
  notifier
]