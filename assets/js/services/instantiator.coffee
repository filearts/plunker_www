module = angular.module "plunker.instantiator", [
]

module.service "instantiator", [ ->
  instantiators = {}
    
  register: (type, findOrCreateFn) ->
    instantiators[type] = findOrCreateFn
    
  findOrCreate: (type, json = {}) ->
    if instantiator = instantiators[type]
      instantiator(json)
    else json

]