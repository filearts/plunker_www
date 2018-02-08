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
        return this.client.get(
            { url: `/plunks/${plunkId}` },
            (error, res, data) => {
                if (!error && res.statusCode !== 200) {
                    error = new Error(data && data.error || `Unexpected response: ${res.statusCode}`);
                    error.statusCode = res.statusCode;

                    return cb(error);
                }

                if (error) return cb(error);

                return cb(null, data);
            }
        );
    }
};
