var Config = require('../config');
var Hoek = require('hoek');
var Redis = require('ioredis');
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

    return dataset.segment + encodeURIComponent(key);
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


exports.setex = internals.setex = function (dataset, key, value, callback) {

    if (!internals.redis) {
        return callback(new Error('Connection not started'));
    }

    var cacheKey = internals.generateKey(dataset, key);
    value = value.toString();

    internals.redis.setex(cacheKey, dataset.ttl, value, function (err) {

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
    internals.redis.get(cacheKey, function (err, result) {

        if (err) {
            return callback(err);
        }

        return callback(null, result);
    });
};


exports.mgetList = internals.mgetList = function (dataset, keys, callback) {

    if (!internals.redis) {
        return callback(new Error('Connection not started'));
    }

    var pipeline = internals.redis.pipeline();

    _.each(keys, function (key) {
        var listKey = internals.generateKey(dataset, key);
        pipeline.lrange(listKey, 0, -1);
    });

    pipeline.exec(function (err, result) {

        if (err) {
            return callback(err);
        }

        // Refer to https://github.com/luin/ioredis
        // result is an array, and each element is an array in form of: [err, value]
        var lists = _.map(result, function (element) {
            return element[1];
        });

        return callback(null, lists);
    });
};


exports.enqueue = internals.enqueue = function (listDataset, countDataset, key, value, callback) {

    if (!internals.redis) {
        return callback(new Error('Connection not started'));
    }

    var listKey = internals.generateKey(listDataset, key);
    var countKey = internals.generateKey(countDataset, key);
    var pipeline = internals.redis.pipeline();

    pipeline
        .lpush(listKey, value)
        .ltrim(listKey, 0, listDataset.size - 1)
        .incr(countKey)
        .exec(function (err, result) {

        if (err) {
            return callback(err);
        }

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

    internals.redis.mget(cacheKeys, function (err, result) {

        if (err) {
            return callback(err);
        }

        if (!result) {
            return callback(null, null);
        }

        return callback(null, result);
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
