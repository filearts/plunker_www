#= require ./../../vendor/tern/node_modules/acorn/acorn
#= require ./../../vendor/tern/node_modules/acorn/acorn_loose
#= require ./../../vendor/tern/node_modules/acorn/util/walk

#= require ./../../vendor/tern/lib/tern
#= require ./../../vendor/tern/lib/def
#= require ./../../vendor/tern/lib/jsdoc
#= require ./../../vendor/tern/lib/infer

module = angular.module "plunker.tern", [
]

module.factory "tern", [ () ->
  defs = []
  session = null
  
  getFile = (filename) ->
    return buffer.content if buffer = session.getBufferByFilename(filename)
    return ""
  
  server = new tern.Server
    getFile: getFile
    async: true
    defs: defs
    debug: true
    plugins: {}
  
  setSession: (set) -> session = set
  
  requestCompletions: (filename, pos, cb) ->
    payload = 
      query:
        type: "completions"
        lineCharPositions: true
        types: true
        docs: true
        file: filename
        end:
          line: pos.row
          ch: pos.column
      files: []
      
    for buffId, buffer of session.buffers when buffer.filename.match(/\.js$/)
      payload.files.push
        type: "full"
        name: buffer.filename
        text: buffer.content
    
    server.request payload, (err, response) ->
      
      range =
        start:
          row: response.start.line
          column: response.start.ch
        end:
          row: response.end.line
          column: response.end.ch
      
      suggestions = []
      suggestions.push(text: completion.name, value: completion.name, range: range) for completion in response.completions
      
      cb(err, suggestions)
]