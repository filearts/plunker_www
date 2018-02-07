'use strict';

const Assert = require('assert');

const Request = require('request');

module.exports = class Plunks {
    constructor(options) {
        Assert.ok(options && typeof options === 'object');
        Assert.ok(options.apiUrl && typeof options.apiUrl === 'string');

        this.client = Request.defaults({
            baseUrl: options.apiUrl,
            json: true,
            timeout: options.timeout || 3000,
        });
    }

    loadPlunkById(plunkId, cb) {
        return this.client.get(`/plunks/${plunkId}`, (error, res, data) => {
            if (error) return cb(error);

            return cb(null, data);
        });
    }
}
