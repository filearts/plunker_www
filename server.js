require("coffee-script");

//process.env.NODE_ENV = "production";

var nconf = require("nconf")
  , http = require("http")
  , server = require("./index");


http.createServer(server).listen(nconf.get("PORT"), function(){
  console.log("Server started");
});