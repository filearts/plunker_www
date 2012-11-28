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
path = require("path")

pkginfo = require("./package.json")


# Set defaults in nconf
require "./configure"

process.env.NODE_ENV = "production"


app = module.exports = express()


github = authom.createServer
  service: "github"
  id: nconf.get("oauth:github:id")
  secret: nconf.get("oauth:github:secret")
  scope: ["gist"]
  
lactateOptions = 
  "max age": "one week"
  
assetOptions =
  src: "#{__dirname}/assets"
  buildDir: "assets/build"
  buildFilenamer: (filename) ->
    dir = path.dirname(filename)
    ext = path.extname(filename)
    base = path.basename(filename, ext)
    
    return path.join dir, "#{base}-#{pkginfo.version}#{ext}"
  helperContext: app.locals

app.set "views", "#{__dirname}/views"
app.set "view engine", "jade"
app.set "view options", layout: false

app.use express.logger()
app.use lactate.static "#{__dirname}/assets/build", lactateOptions
app.use lactate.static "#{__dirname}/assets", lactateOptions
app.use "/css/font", lactate.static("#{__dirname}/assets/vendor/Font-Awesome-More/font/", lactateOptions)

if process.env.NODE_ENV is "production"
  app.locals.js = (route) -> """<script src="/js/#{route}-#{pkginfo.version}.js"></script>"""
  app.locals.css = (route) -> """<link rel="stylesheet" href="/css/#{route}-#{pkginfo.version}.css" />"""
else
  app.use assets(assetOptions)
  
app.use express.cookieParser()
app.use express.bodyParser()
app.use require("./middleware/session").middleware()
app.use require("./middleware/expose").middleware
  "url": nconf.get("url")
  "package": pkginfo
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

# /////////////////////////////////

app.get "/auth/:service", (req, res, next) ->
  req.headers.host = nconf.get("host")
  
  next()

app.get "/auth/:service", authom.app


authom.on "auth", (req, res, auth) ->
  console.log "Auth success"
  res.render "auth/success", auth: auth


authom.on "error", (req, res, data) ->
  console.log "Auth error"
  res.status 403
  res.render "auth/error", auth: data
  
# /////////////////////////////////

app.get "/*", (req, res) ->
  res.render "landing"
