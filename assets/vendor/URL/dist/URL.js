/*! URL.js - v1.2.2 - 2012-10-22
* https://github.com/stevoland/URL.js
 Licensed MIT */

(function (root, factory) {
    if (typeof define === 'function' && define.amd) {
        define([], factory);
    } else {
        root.URL = factory();
    }
}(this, function () {

    var options = {
        strictMode: false,
        key: [
            "source",
            "protocol",
            "authority",
            "userInfo",
            "user",
            "password",
            "host",
            "port",
            "relative",
            "path",
            "directory",
            "file",
            "query",
            "anchor"
        ],
        q: {
            name:   "queryKey",
            parser: /(?:^|&)([^&=]*)=?([^&]*)/g
        },
        parser: {
            strict: /^(?:([^:\/?#]+):)?(?:\/\/((?:(([^:@]*)(?::([^:@]*))?)?@)?([^:\/?#]*)(?::(\d*))?))?((((?:[^?#\/]*\/)*)([^?#]*))(?:\?([^#]*))?(?:#(.*))?)/,
            loose:  /^(?:(?![^:@]+:[^:@\/]*@)([^:\/?#.]+):)?(?:\/\/)?((?:(([^:@]*)(?::([^:@]*))?)?@)?([^:\/?#]*)(?::(\d*))?)(((\/(?:[^?#](?![^?#\/]*\.[^?#\/.]+(?:[?#]|$)))*\/?)?([^?#\/]*))(?:\?([^#]*))?(?:#(.*))?)/
        }
    };


    /**
     * Parse a URI into an object
     * Credit: http://blog.stevenlevithan.com/archives/parseuri
     *
     * @param  {string} str     URI to parse
     * @return {object}         URI object
     */
    function parse (str) {
        var o   = options,
            m   = o.parser[o.strictMode ? "strict" : "loose"].exec(str),
            uri = {},
            i   = 14;

        while (i--) {
            uri[o.key[i]] = m[i] || "";
        }

        uri[o.q.name] = {};
        uri[o.key[12]].replace(o.q.parser, function ($0, $1, $2) {
            if ($1) {
                uri[o.q.name][$1] = $2;
            }
        });

        return uri;
    }


    /**
     * Build a URI from an object
     * Credit: https://gist.github.com/1073037
     *
     * @param  {object} u       URI object
     * @return {string}         URI
     */
    function make (u) {

        var uri = "",
            k;

        if (u.protocol) {
            uri += u.protocol + "://";
        }

        if (u.user) {
            uri += u.user;
        }

        if (u.password) {
            uri += ":" + u.password;
        }

        if (u.user || u.password) {
            uri += "@";
        }

        if (u.host) {
            uri += u.host;
        }

        if (u.port) {
            uri += ":" + u.port;
        }

        if (u.path) {
            uri += u.path;
        }

        var qk = u.queryKey;
        var qs = [];

        for (k in qk) {

            if (!qk.hasOwnProperty(k)) {
                continue;
            }

            var v = encodeURIComponent(qk[k]);

            k = encodeURIComponent(k);

            if (v) {
                qs.push(k + "=" + v);
            } else {
                qs.push(k);
            }
        }

        if (qs.length > 0) {
            uri += "?" + qs.join("&");
        }

        if (u.anchor) {
            uri += "#" + u.anchor;
        }

        return uri;
    }

    return {
        parse: parse,
        make: make
    };

}));