nconf = require("nconf")

env = process.env.NODE_ENV or "development"

nconf.use("memory")
  .argv()
  .env()
  .file({file: "config.#{env}.json"})
  .defaults({
    PORT: 8080
  })

unless host = nconf.get("host")
  console.error "The 'host' option is required for Plunker to run."
  process.exit(1)
