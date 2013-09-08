request = require("request")
nconf = require("nconf")

module.exports.middleware = (options = {}) ->
  
  apiUrl = nconf.get("url:api")
  domain = nconf.get("host")
  self = @
  
  middleware = (req, res, next) ->
    handleRequest = (err, innerRes, body) ->
      return next(err) if err
      
      return createSession() unless body.id
      
      addCookie body
      
    createSession = ->
      request.post "#{apiUrl}/sessions", json: true, handleRequest
      
    addCookie = (data) ->
      res.cookie "plnk_session", data.sessid,
        domain: domain
        expires: new Date(Date.now() + 1000 * 60 * 60 * 24 * 14) # Two weeks
      
      res.expose data, "plnkr.session"
      
      next()
  
    if sessid = req.cookies.plnk_session
      request.get "#{apiUrl}/sessions/#{sessid}", json: true, handleRequest
    else
      createSession()
