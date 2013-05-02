module = angular.module "plunker.stream", [
  "firebase"
]

module.service "stream", [ () ->
  new class Stream
  
    connect: (streamId) ->
      
]