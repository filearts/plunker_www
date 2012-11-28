coffee = require("coffee-script")
less = require("less")
assets = require("connect-assets")
path = require("path")
fs = require("fs")
rimraf = require("rimraf")

pkginfo = require("./package.json")


assets
  src: "#{__dirname}/assets"
  build: true
  minify: true
  buildDir: "assets/build"
  buildFilenamer: (filename) ->
    dir = path.dirname(filename)
    ext = path.extname(filename)
    base = path.basename(filename, ext)
    
    return path.join dir, "#{base}-#{pkginfo.version}#{ext}"

if fs.existsSync("#{__dirname}/assets/build") then rimraf.sync("#{__dirname}/assets/build")
  
console.log "Building landing.js"
js("pages/landing")

console.log "Building landing.css"
css("pages/landing")

console.log "Building editor.js"
js("pages/editor")

console.log "Building editor.css"
css("pages/editor")