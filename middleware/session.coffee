nconf = require("nconf")
request = require("request")

module.exports.middleware = (options = {}) ->
  
  apiUrl = nconf.get("url:api")
  
  (req, res, next) ->
    fetchSession = (sessid) ->
      return createSession() unless sessid
      
      request { method: "GET", url: "#{apiUrl}/sessions/#{sessid}", json: true },  (err, response, body) ->
        if err or response.statusCode >= 400 then createSession()
        else finalize(body)
      
    createSession = ->
      
      request { method: "POST", url: "#{apiUrl}/sessions", body: {}, json: true }, (err, response, body) ->
        if err or response.statusCode >= 400
          console.error "[ERR] Failed to create session: #{JSON.stringify(err or body)}"
          finalize({})
        else finalize(body)
    
    finalize = (session) ->
      res.expose session, "_plunker.session"
      next()
    
    if sessid = req.cookies.plnk_session then fetchSession(sessid)
    else createSession()
