var Async = require('async');
var Config = require('../config');
var Hoek = require('hoek');
var Redis = require('redis');
var Utils = require('./utils');
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

    var cacheKey = internals.generateKey(dataset, key);
    internals.client.get(cacheKey, function (err, resultString) {

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


exports.getList = internals.getList = function (dataset, key, min, callback) {

    if (!internals.client) {
        return callback(new Error('Connection not started'));
    }

    var cacheKey = internals.generateKey(dataset, key);
    internals.client.lrange(cacheKey, 0, -1, function (err, result) {

        if (err) {
            return callback(err);
        }

        if (!result) {
            return callback(null, null);
        }

        // remove the small orderIds
        var validResult = _.filter(result, function (item) { return min < item; });

        if (validResult.length === 0) {
            return callback(null, null);
        }

        return callback(null, validResult);
    });
};


exports.lpush = internals.lpush = function (dataset, key, value, callback) {

    if (!internals.client) {
        return callback(new Error('Connection not started'));
    }

    var cacheKey = internals.generateKey(dataset, key);
    var valueString = Utils.padZero(value, 19);  // zero pad the number string to facility the filter process when getList

    internals.client.lpush(cacheKey, valueString, function (err, result) {

        if (err) {
            return callback(err);
        }

        if (!result) {
            return callback(null, null);
        }

        // Limit the values list size to 500
        internals.client.ltrim(cacheKey, 0, 500);

        return callback(null, result);
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

    if (!keys || keys.length === 0) {
        return callback(null, null);
    }

    var cacheKeys = _.map(keys, function (key) {
        return internals.generateKey(dataset, key);
    });

    internals.client.mget(cacheKeys, function (err, results) {

        if (err) {
            return callback(err);
        }

        if (!results) {
            return callback(null, null);
        }

        return callback(null, results);
    });
};


exports.mset = function (dataset, keys, values, callback) {

    if (!internals.client) {
        return callback(new Error('Connection not started'));
    }

    var keyValues = _.map(keys, function (key, index) {

        var cacheKey = internals.generateKey(dataset, key);
        var valueString = JSON.stringify(values[index]);
        return [cacheKey, valueString];
    });

    internals.client.mset(_.flatten(keyValues), function (err) {

        if (err) {
            return callback(err);
        }

        return callback(null);
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
        cacheUserName: function (next) {

            internals.set(c.USER_NAME_ID_CACHE, userName, userId, function (err) {

                if (err) {
                    return next(err);
                }

                next(null);
            });
        },
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

            var userInfo = userId + ':' + userName;

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


exports.validateToken = function (token, callback) {

    internals.get(c.API_TOKEN_CACHE, token, function (err, result) {
        if (err) {
            console.error(err);
            return callback(err);
        }

        if (!result) {
            return callback('Token Not Found');
        }

        var userInfo = _.object(['id', 'username'], result.split(':'));
        callback(null, userInfo);
    });
};
