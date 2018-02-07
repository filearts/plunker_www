'use strict';

const Assert = require('assert');
const Url = require('url');

const EXTRACT_PLUNK_RX = /^\/edit\/([a-zA-Z0-9]+)\/$/;

module.exports = class Oembed {
    constructor(options) {
        Assert.ok(options && typeof options === 'object');
        Assert.ok(options.wwwUrl && typeof options.wwwUrl === 'string');

        this.wwwUrl = options.wwwUrl;
        this.parsedWwwUrl = Url.parse(options.wwwUrl);
    }

    extractPlunkIdFromUrl(url, cb) {
        const parsedUrl = Url.parse(url);

        if (parsedUrl.host !== this.parsedWwwUrl.host) {
            const error = new Error(`Invalid host: ${parsedUrl.host}`);
            error.statusCode = 400;
            return cb(error);
        }

        const basePath =
            this.parsedWwwUrl.pathname.charAt(
                this.parsedWwwUrl.pathname.length - 1
            ) === '/'
                ? this.parsedWwwUrl.pathname.slice(
                      0,
                      this.parsedWwwUrl.pathname.length - 2
                  )
                : this.parsedWwwUrl.pathname;

        if (parsedUrl.pathname.indexOf(basePath) !== 0) {
            const error = new Error(
                `The url path must be a child of: ${
                    request.server.app.config.www.uri
                }`
            );
            error.statusCode = 400;
            return cb(error);
        }

        const parsedPath = parsedUrl.pathname.slice(basePath.length);
        const matches = parsedPath.match(EXTRACT_PLUNK_RX);

        if (!matches) {
            const error = new Error(
                'The url path must be either: 1) /edit/:plunkId/; or 2) /plunk/:plunkId'
            );
            error.statusCode = 400;
            return cb(error);
        }

        const plunkId = matches[1];

        return cb(null, plunkId);
    }
};
