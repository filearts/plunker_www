require("coffee-script");

var nconf = require("nconf")
  , http = require("http")
  , server = require("./index");


http.createServer(server).listen(nconf.get("PORT"));