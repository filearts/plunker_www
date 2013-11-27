nconf = require("nconf")

host = nconf.get("host")
hostEsc = host.replace(/[-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/g, "\\$&")
embedRe = new RegExp("^embed\.#{hostEsc}$")

module.exports.middleware = (config = {}) ->
  (req, res, next) ->
    # Rewrite plunk previews to the expected path
    if matches = req.headers.host.match(embedRe)
      req.url = "/embed/#{req.url}"

    next()