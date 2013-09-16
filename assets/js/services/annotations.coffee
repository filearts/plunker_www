module = angular.module "plunker.service.annotations", []

module.factory "annotations", ->
  annotations: {}
  
  update: (filename, annotations = []) ->
    angular.copy annotations, (@annotations[filename] ||= [])
  
  rename: (old_filename, new_filename) ->
    @annotations[new_filename] = @annotations[old_filename] or []
    delete @annotations[old_filename]
  
  remove: (filename) ->
    delete @annotations[filename]
    
  hasError: ->
    for filename, annotations of @annotations
      
      return filename for annotation in annotations when annotation.type is "error"
    
    return false