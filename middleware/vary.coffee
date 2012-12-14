module.exports.middleware = (options = {}) ->
  (req, res, next) ->
    res.set "Vary", "Accept-Encoding, Cookie"
    next()
