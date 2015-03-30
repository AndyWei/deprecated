var Async = require('async');
var Hoek = require('hoek');
var c = require('./constants');
var rand = require('rand-token');

var cache = null;

exports.attach = function (server) {

    Hoek.assert(!cache, 'Token cache should only be set once.');
    cache = server.cache({
        segment: 'token',
        expiresIn: 60 * 60 * 1000
    });
};


exports.detach = function () {

    cache = null;
};


// Generate a 20 character alpha-numeric token and store it in cache
exports.generate = function (userId, callback) {

    Hoek.assert(cache, 'Token cache should be set beforehand.');

    userId = userId.toString();
    Async.auto({
        existedToken: function (next) {

            cache.get(userId, function (err, value) {

                if (err) {
                    return next(err);
                }

                if (value) { // there is a token already, so fake a err here to stop generating new token
                    return next(true, value);
                }

                next(null, null);
            });
        },
        generateToken: function (next) {

            var token = rand.generate(c.TOKEN_LENGTH);
            next(null, token);
        },
        cacheToken: ['existedToken', 'generateToken', function (next, results) {

            cache.set(results.generateToken, userId, 0, function (err) {

                if (err) {
                    return next(err);
                }

                next(null);
            });
        }],
        cacheUserId: ['existedToken', 'generateToken', function (next, results) {

            cache.set(userId, results.generateToken, 0, function (err) {

                if (err) {
                    return next(err);
                }

                next(null);
            });
        }]
    }, function (err, results) {

        if (err === true) {
            return callback(null, results.existedToken); // just return the existedToken
        }

        if (err) {
            console.error(err);
            return callback(err);
        }

        callback(null, results.generateToken);
    });
};


exports.destroy = function (token, callback) {

    Hoek.assert(cache, 'Token cache should be set beforehand.');
    cache.drop(token, function (err) {

        if (err) {
            return callback(err);
        }

        callback(null, true);
    });
};


exports.validate = function (token, callback) {

    Hoek.assert(cache, 'Token cache should be set beforehand.');
    cache.get(token, function (err, value) {

        if (err) {
            return callback(err);
        }

        if (!value) {
            return callback(new Error(c.TOKEN_INVALID));
        }

        callback(null, value);
    });
};

