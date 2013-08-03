module.exports.middleware = (options = {}) ->
  (req, res, next) ->
    return next() unless options.from and options.to
    
    if req.get('host') is options.from
      res.redirect "http://#{options.to}#{req.url}"
    else
      next()