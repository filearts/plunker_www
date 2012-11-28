nconf = require("nconf")

nconf.use("memory")
  .argv()
  .env()
  .file({file: "config.json"})
  .defaults({
    PORT: 8080
  })

unless host = nconf.get("host")
  console.error "The 'host' option is required for Plunker to run."
  process.exit(1)

if nconf.get("nosubdomains")
  nconf.set("url:www", "http://#{host}")
  nconf.set("url:raw", "http://#{host}/raw");
  nconf.set("url:run", "http://#{host}/run");
  nconf.set("url:api", "http://plnkr.co/api");
  nconf.set("url:embed", "http://#{host}/embed");

else
  nconf.set("url:www", "http://#{host}")
  nconf.set("url:run", "http://run.plnkr.co")
  nconf.set("url:api", "http://api.plnkr.co")
  nconf.set("url:embed", "http://embed.plnkr.co")