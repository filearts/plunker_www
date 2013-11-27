nconf = require("nconf")

host = nconf.get("host")
hostEsc = host.replace(/[-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/g, "\\$&")
embedRe = new RegExp("^embed\.#{hostEsc}$")
pathRe = /^\/embed\//

module.exports.middleware = (config = {}) ->
  (req, res, next) ->
    # Rewrite plunk previews to the expected path
    if embedRe.test(req.headers.host) and not pathRe.test(req.url)
      req.url = "/embed#{req.url}"

    next()