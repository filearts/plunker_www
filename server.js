var forever = require('forever-monitor');

var child = new (forever.Monitor)('index.js', {
  max: 10,
});

child.on('exit', function () {
  console.log('[ERR] App killed after 10 fails.');
});

child.start();