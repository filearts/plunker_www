module.exports.middleware = (options = {}) ->
  (req, res, next) ->
    res.header "Vary", "Accept-Encoding", "Cookie"
    next()
