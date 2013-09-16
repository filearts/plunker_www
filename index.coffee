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



server = express()


# Configure express
server.enable "trust proxy"

server.engine "html", require("hbs").__express

server.set "view engine", "html"
server.set "views", "#{__dirname}/views"


# Express middleware

server.use express.cookieParser()
server.use lactate.static "#{__dirname}/public",
  "max age": "one week"
  "cache": false
  
#collab = require "./collab"
#collab.extend server

server.use server.router

  
server.get "/auth/:service", (req, res, next) ->
  req.headers.host = nconf.get("host")
  
  next()

server.get "/auth/:service", authom.app

sessionMiddleware = require("./middleware/session.coffee").middleware()





server.get "/*", (req, res) ->
  res.render "index", timestamp: Date.now()

expstate.extend server

server.expose nconf.get("url"), "_plunker.url"


module.exports = server