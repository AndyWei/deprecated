var Async = require('async');
var Config = require('../config');
var Hoek = require('hoek');
var Redis = require('ioredis');
var Utils = require('./utils');
var c = require('./constants');
var rand = require('rand-token');
var _ = require('underscore');

var exports = module.exports = {};
var internals = {};

internals.settings = {
    host: Config.get('/redis/host'),
    // password: Config.get('/redis/password'),
    port: Config.get('/redis/port')
};

internals.redis = null;

internals.generateKey = function (dataset, key) {

    return encodeURIComponent(dataset.segment) + ':' + encodeURIComponent(key);
};

exports.start = function (callback) {

    if (internals.redis) {
        return Hoek.nextTick(callback)();
    }

    var redis = new Redis(internals.settings.port, internals.settings.host);

    // Listen to errors
    redis.on('error', function (err) {

        if (!internals.redis) {   // Failed to connect
            redis.end();
            return callback(err);
        }
    });

    // Wait for connection
    redis.once('connect', function () {

        internals.redis = redis;
        return callback();
    });
};


exports.stop = function () {

    if (internals.redis) {
        internals.redis.removeAllListeners();
        internals.redis.quit();
        internals.redis = null;
    }
};


exports.set = internals.set = function (dataset, key, value, callback) {

    if (!internals.redis) {
        return callback(new Error('Connection not started'));
    }

    var cacheKey = internals.generateKey(dataset, key);
    var valueString = JSON.stringify(value);

    internals.redis.setex(cacheKey, dataset.ttl, valueString, function (err) {

        if (err) {
            return callback(err);
        }

        return callback(null);
    });
};


exports.get = internals.get = function (dataset, key, callback) {

    if (!internals.redis) {
        return callback(new Error('Connection not started'));
    }

    var cacheKey = internals.generateKey(dataset, key);
    internals.redis.get(cacheKey, function (err, resultString) {

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


exports.getList = internals.getList = function (dataset, key, min, callback) {

    if (!internals.redis) {
        return callback(new Error('Connection not started'));
    }

    var cacheKey = internals.generateKey(dataset, key);
    internals.redis.lrange(cacheKey, 0, -1, function (err, result) {

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

    if (!internals.redis) {
        return callback(new Error('Connection not started'));
    }

    var cacheKey = internals.generateKey(dataset, key);
    var valueString = Utils.padZero(value, 19);  // zero pad the number string to facility the filter process when getList

    internals.redis.lpush(cacheKey, valueString, function (err, result) {

        if (err) {
            return callback(err);
        }

        if (!result) {
            return callback(null, null);
        }

        // Limit the values list size to 500
        internals.redis.ltrim(cacheKey, 0, 500);

        return callback(null, result);
    });
};


exports.drop = function (dataset, key, callback) {

    if (!internals.redis) {
        return callback(new Error('Connection not started'));
    }

    internals.redis.del(internals.generateKey(dataset, key), function (err) {

        return callback(err);
    });
};


exports.incr = function (dataset, key, callback) {

    if (!internals.redis) {
        return callback(new Error('Connection not started'));
    }

    internals.redis.incr(internals.generateKey(dataset, key), function (err, result) {

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

    if (!internals.redis) {
        return callback(new Error('Connection not started'));
    }

    if (!keys || keys.length === 0) {
        return callback(null, null);
    }

    var cacheKeys = _.map(keys, function (key) {
        return internals.generateKey(dataset, key);
    });

    internals.redis.mget(cacheKeys, function (err, results) {

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

    if (!internals.redis) {
        return callback(new Error('Connection not started'));
    }

    var keyValues = _.map(keys, function (key, index) {

        var cacheKey = internals.generateKey(dataset, key);
        return [cacheKey, values[index]];
    });

    internals.redis.mset(_.flatten(keyValues), function (err) {

        if (err) {
            return callback(err);
        }

        return callback(null);
    });
};


// Generate a 20 character alpha-numeric token and store it in cache
exports.generateBearerToken = function (personId, name, callback) {

    personId = personId.toString();
    name = name.toString();

    Async.auto({
        generateToken: function (next) {

            var token = rand.generate(c.TOKEN_LENGTH);
            return next(null, token);
        },
        cacheToken: ['generateToken', function (next, results) {

            var personInfo = personId + ':' + name;

            internals.set(c.AUTH_TOKEN_CACHE, results.generateToken, personInfo, function (err) {

                if (err) {
                    return next(err);
                }

                return next(null);
            });
        }]
    }, function (err, results) {

        if (err) {
            console.error(err);
            return callback(err);
        }

        return callback(null, results.generateToken);
    });
};


exports.validateToken = function (token, callback) {

    internals.get(c.AUTH_TOKEN_CACHE, token, function (err, result) {
        if (err) {
            console.error(err);
            return callback(err);
        }

        if (!result) {
            return callback('Token Not Found');
        }

        var personInfo = _.object(['id', 'name'], result.split(':'));
        personInfo.token = token;

        return callback(null, personInfo);
    });
};


exports.updateName = function (token, personId, name, callback) {

    personId = personId.toString();
    name = name.toString();

    var personInfo = personId + ':' + name;

    internals.set(c.AUTH_TOKEN_CACHE, token, personInfo, function (err) {

        if (err) {
            console.error(err);
            return callback(err);
        }

        return callback(null);
    });
};
