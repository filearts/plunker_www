var Assert = require('assert');
var Request = require('request');


exports.middleware = function(options) {
    Assert.ok(typeof options === 'object', 'The middlware `maybeLoadPlunk` must be created with an options object.');
    Assert.ok(options.apiUrl, 'The middlware `maybeLoadPlunk` must be passed an `apiUrl` option.');
    
    var apiUrl = 'https:' + options.apiUrl;
    
    return maybeLoadPlunk;
    
    
    function maybeLoadPlunk(req, res, next) {
        if (req.params.plunkId && req.params.plunkId.match(/^[a-zA-Z0-9]+$/)) {
            Request.get(apiUrl + '/plunks/' + req.params.plunkId, { json: true, timeout: 3000, qs: { v: req.query.v } }, function (err, res, body) {
                if (!err && body) req.plunk = body;
                
                next();
            });
        } else {
            next();
        }
    }
};

