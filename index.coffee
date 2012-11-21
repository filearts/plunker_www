coffee = require("coffee-script")
less = require("less")
jade = require("jade")
express = require("express")
assets = require("connect-assets")
nconf = require("nconf")
authom = require("authom")
request = require("request")
sharejs = require("share")
lactate = require("lactate")


# Set defaults in nconf
require "./configure"

github = authom.createServer
  service: "github"
  id: nconf.get("oauth:github:id")
  secret: nconf.get("oauth:github:secret")
  scope: ["gist"]
  

#process.env.NODE_ENV = "production"


app = module.exports = express()

app.set "views", "#{__dirname}/views"
app.set "view engine", "jade"
app.set "view options", layout: false

app.use express.logger()
app.use assets
  src: "#{__dirname}/assets"
app.use express.compress()
app.use "/css/font", lactate.static("#{__dirname}/assets/vendor/Font-Awesome-More/font/")
app.use lactate.static "#{__dirname}/assets"
app.use express.cookieParser()
app.use express.bodyParser()
app.use require("./middleware/session").middleware()
app.use require("./middleware/expose").middleware
  "url": nconf.get("url")
  "package": require("./package.json")
  "bootstrap": null

sharejs.server.attach app,
  db:
    type: "none"
    
app.use app.router

app.use express.errorHandler()

app.get "/partials/:partial", (req, res, next) ->
  res.render "partials/#{req.params.partial}"

app.get "/edit/*", (req, res, next) ->
  res.render "editor"
  
app.all "/edit/", (req, res, next) ->
  res.header("Access-Control-Allow-Origin", req.headers.origin or "*")
  res.header("Access-Control-Allow-Methods", "OPTIONS,GET,PUT,POST,DELETE")
  res.header("Access-Control-Allow-Headers", "Authorization, User-Agent, Referer, X-Requested-With, Proxy-Authorization, Proxy-Connection, Accept-Language, Accept-Encoding, Accept-Charset, Connection, Content-Length, Host, Origin, Pragma, Accept-Charset, Cache-Control, Accept, Content-Type")
  res.header("Access-Control-Expose-Headers", "Link")
  res.header("Access-Control-Max-Age", "60")

  if "OPTIONS" == req.method then res.send(200)
  else next()

app.post "/edit/", (req, res, next) ->    
  res.header "X-XSS-Protection", 0
  
  bootstrap =
    description: ""
    tags: []
    files: {}

  if req.body.files
    for filename, file of req.body.files
      bootstrap.files[filename] =
        filename: filename
        content: if typeof file is "string" then file else file.content or ""
      
  res.local.bootstrap = bootstrap
  res.render "editor"

app.all "/edit", (req, res, next) -> res.redirect("/edit/", 302)

app.get "/*", (req, res) ->
  res.render "landing"
