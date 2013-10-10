express = require("express")
expstate = require("express-state")
lactate = require("lactate")
request = require("request")
authom = require("authom")
nconf = require("nconf")


# Configure authom for github OAuth

github = authom.createServer
  service: "github"
  id: nconf.get("oauth:github:id")
  secret: nconf.get("oauth:github:secret")
  scope: ["gist"]

authom.on "error", (req, res, data) ->
  res.expose data, "_plunker.auth_error"
  res.send """
    <script type="text/javascript">
      debugger
      #{res.locals.state}
      if (window.opener && window.opener.postMessage) {
        window.opener.postMessage(JSON.strigify({'event': "auth_error",'message': _plunker.auth_error}), "#{nconf.get("url:www")}");
      }
      window.close()
    </script>
  """

authom.on "auth", (req, res, data) ->
  res.expose data, "_plunker.auth_data"
  res.send """
    <script type="text/javascript">
      debugger
      #{res.locals.state}
      if (window.opener && window.opener.postMessage) {
        window.opener.postMessage(JSON.strigify({'event': "auth_data",'message': _plunker.auth_data}), "#{nconf.get("url:www")}");
      }
      window.close()
    </script>
  """



server = express()

expstate.extend server


# Configure express
server.enable "trust proxy"

server.engine "html", require("hbs").__express

server.set "view engine", "html"
server.set "views", "#{process.env.PWD}/views"

console.log "Serving views from", "#{process.env.PWD}/public"


# Express middleware

server.use lactate.static "#{process.env.PWD}/public",
  "max age": "one week"
  "cache": false
server.use express.cookieParser()

#collab = require "./collab"
#collab.extend server

server.use express.logger()
server.use server.router

  
server.get "/auth/:service", (req, res, next) ->
  req.headers.host = nconf.get("host")
  
  next()

server.get "/auth/:service", authom.app



sessionMiddleware = require("./middleware/session.coffee").middleware()


server.get "/edit/*", sessionMiddleware, (req, res) -> res.render "index", timestamp: Date.now()
server.get "/", sessionMiddleware, (req, res) -> res.render "index", timestamp: Date.now()

server.expose nconf.get("url"), "_plunker.url"


module.exports = server