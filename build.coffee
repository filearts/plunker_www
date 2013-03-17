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
  minifyBuilds: true
  buildDir: "build"
  buildFilenamer: (filename) ->
    dir = path.dirname(filename)
    ext = path.extname(filename)
    base = path.basename(filename, ext)
    
    return path.join dir, "#{base}-#{pkginfo.version}#{ext}"


if fs.existsSync("#{__dirname}/build") then rimraf.sync("#{__dirname}/build")

  
console.log "Building landing.js"
js("apps/landing")

console.log "Building landing.css"
css("apps/landing")

console.log "Building editor.js"
js("apps/editor")

console.log "Building editor.css"
css("apps/editor")