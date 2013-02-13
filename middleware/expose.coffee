module.exports.middleware = (options = {}) ->
  (req, res, next) ->
    res.expose ||= {}
    
    for key, value of options
      res.expose[key] ||= value
    
    for key, value of res.expose
      res.locals[key] = value 
    next()