module = angular.module "plunker.service.types", [
]


module.factory "types", ->
  types =
    html:
      regex: /\.html$/i
      mime: "text/html"
    javascript:
      regex: /\.js$/i
      mime: "text/javascript"
    coffee:
      regex: /\.coffee$/i
      mime: "text/coffee"
    css:
      regex: /\.css$/i
      mime: "text/css"
    text:
      regex: /\.txt$/
      mime: "text/plain"
  
  for name, type of types
    type.name = name
  
  types: types
  getByFilename: (filename) ->
    for name, mode of types
      if mode.regex.test(filename) then return mode
    
    return types.text


