var Async = require('async');
var Config = require('../config');
var Hoek = require('hoek');
var Redis = require('redis');
var c = require('./constants');
var rand = require('rand-token');
var _ = require('underscore');


var internals = {};

internals.settings = {
    host: Config.get('/redis/host'),
    // password: Config.get('/redis/password'),
    port: Config.get('/redis/port')
};

internals.client = null;

exports.start = function (callback) {

    if (internals.client) {
        return Hoek.nextTick(callback)();
    }

    var client = Redis.createClient(internals.settings.port, internals.settings.host);

    if (internals.settings.password) {
        client.auth(internals.settings.password);
    }

    if (internals.settings.database) {
        client.select(internals.settings.database);
    }

    // Listen to errors

    client.on('error', function (err) {

        if (!internals.client) {   // Failed to connect
            client.end();
            return callback(err);
        }
    });

    // Wait for connection

    client.once('connect', function () {

        internals.client = client;
        return callback();
    });
};


exports.stop = function () {

    if (internals.client) {
        internals.client.removeAllListeners();
        internals.client.quit();
        internals.client = null;
    }
};


exports.get = internals.get = function (dataset, key, callback) {

    if (!internals.client) {
        return callback(new Error('Connection not started'));
    }

    internals.client.get(internals.generateKey(dataset, key), function (err, resultString) {

        if (err) {
            return callback(err);
        }

        if (!resultString) {
            return callback(null, null);
        }

        var result = JSON.parse(resultString);
        return callback(null, result);
    });
};


exports.set = internals.set = function (dataset, key, value, callback) {

    if (!internals.client) {
        return callback(new Error('Connection not started'));
    }

    var cacheKey = internals.generateKey(dataset, key);
    var valueString = JSON.stringify(value);

    internals.client.setex(cacheKey, dataset.ttl, valueString, function (err) {

        if (err) {
            return callback(err);
        }

        callback(null, null);
    });
};


exports.drop = function (dataset, key, callback) {

    if (!internals.client) {
        return callback(new Error('Connection not started'));
    }

    internals.client.del(internals.generateKey(dataset, key), function (err) {

        return callback(err);
    });
};


exports.incr = function (dataset, key, callback) {

    if (!internals.client) {
        return callback(new Error('Connection not started'));
    }

    internals.client.incr(internals.generateKey(dataset, key), function (err, result) {

        if (err) {
            return callback(err);
        }

        if (!result) {
            return callback(null, null);
        }

        return callback(null, result);
    });
};


exports.mget = function (dataset, keys, callback) {

    if (!internals.client) {
        return callback(new Error('Connection not started'));
    }

    var generatedKeys = _.map(keys, function (key) {
        return internals.generateKey(dataset, key);
    });

    internals.client.mget(generatedKeys, function (err, results) {

        if (err) {
            return callback(err);
        }

        if (!results) {
            return callback(null, null);
        }

        var zeroFilledResults = _.map(results, function (result) {
            return (result === null) ? '0' : result;
        });

        return callback(null, zeroFilledResults);
    });
};


internals.generateKey = function (dataset, key) {

    return encodeURIComponent(dataset.segment) + ':' + encodeURIComponent(key);
};


// Generate a 20 character alpha-numeric token and store it in cache
exports.generateBearerToken = function (userId, userName, callback) {

    userId = userId.toString();
    userName = userName.toString();

    Async.auto({
        existedToken: function (next) {

            internals.get(c.API_TOKEN_CACHE, userId, function (err, value) {

                if (err) {
                    return next(err);
                }

                if (value) { // there is a token already, so fake a err here to stop generating new token
                    return next('token_found', value);
                }

                next(null, null);
            });
        },
        generateToken: function (next) {

            var token = rand.generate(c.TOKEN_LENGTH);
            next(null, token);
        },
        cacheToken: ['existedToken', 'generateToken', function (next, results) {

            var userInfo = {
                id: userId,
                username: userName
            };

            internals.set(c.API_TOKEN_CACHE, results.generateToken, userInfo, function (err) {

                if (err) {
                    return next(err);
                }

                next(null);
            });
        }],
        cacheUserId: ['existedToken', 'generateToken', function (next, results) {

            internals.set(c.API_TOKEN_CACHE, userId, results.generateToken, function (err) {

                if (err) {
                    return next(err);
                }

                next(null);
            });
        }]
    }, function (err, results) {

        if (err === 'token_found') {
            return callback(null, results.existedToken); // just return the existedToken
        }

        if (err) {
            console.error(err);
            return callback(err);
        }

        callback(null, results.generateToken);
    });
};
