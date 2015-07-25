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

    return String(dataset.segment) + String(key);
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


//// pairs
exports.drop = function (dataset, key, callback) {

    Hoek.assert(internals.redis, 'Connection not started');

    internals.redis.del(internals.generateKey(dataset, key), function (err) {

        if (typeof callback === 'function') {
            return callback(err);
        }
    });
};


exports.incr = function (dataset, key, callback) {

    Hoek.assert(internals.redis, 'Connection not started');

    internals.redis.incr(internals.generateKey(dataset, key), function (err, result) {

        if (typeof callback === 'function') {
            if (err) {
                return callback(err);
            }

            return callback(null, result);
        }
    });
};


exports.mget = function (dataset, keys, callback) {

    Hoek.assert(typeof callback === 'function', 'Invalid callback');
    Hoek.assert(internals.redis, 'Connection not started');

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

    Hoek.assert(internals.redis, 'Connection not started');

    var keyValues = _.map(keys, function (key, index) {

        var cacheKey = internals.generateKey(dataset, key);
        return [cacheKey, values[index]];
    });

    internals.redis.mset(_.flatten(keyValues), function (err) {

        if (typeof callback === 'function') {
            if (err) {
                return callback(err);
            }

            return callback(null);
        }
    });
};


exports.setex = internals.setex = function (dataset, key, value, callback) {

    Hoek.assert(internals.redis, 'Connection not started');

    var cacheKey = internals.generateKey(dataset, key);
    value = value.toString();

    internals.redis.setex(cacheKey, dataset.ttl, value, function (err) {

        if (typeof callback === 'function') {
            if (err) {
                return callback(err);
            }

            return callback(null);
        }
    });
};


exports.get = internals.get = function (dataset, key, callback) {

    Hoek.assert(typeof callback === 'function', 'Invalid callback');
    Hoek.assert(internals.redis, 'Connection not started');

    var cacheKey = internals.generateKey(dataset, key);
    internals.redis.get(cacheKey, function (err, result) {

        if (err) {
            return callback(err);
        }

        return callback(null, result);
    });
};


//// Lists
// Get all the elements from multi lists
exports.mgetlist = internals.mgetlist = function (dataset, keys, callback) {

    Hoek.assert(typeof callback === 'function', 'Invalid callback');
    Hoek.assert(internals.redis, 'Connection not started');

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


// Get all the elements from a lists
exports.getlist = internals.getlist = function (dataset, key, callback) {

    Hoek.assert(typeof callback === 'function', 'Invalid callback');
    Hoek.assert(internals.redis, 'Connection not started');

    var listKey = internals.generateKey(dataset, key);
    internals.redis.lrange(listKey, 0, -1, function (err, result) {

        if (err) {
            return callback(err);
        }

        return callback(null, result);
    });
};


exports.pushlist = internals.pushlist = function (dataset, key, value, callback) {

    Hoek.assert(internals.redis, 'Connection not started');

    var listKey = internals.generateKey(dataset, key);
    var pipeline = internals.redis.pipeline();

    pipeline
        .lpush(listKey, value)
        .ltrim(listKey, 0, dataset.size - 1)
        .exec(function (err, result) {

        if (typeof callback === 'function') {
            if (err) {
                return callback(err);
            }

            return callback(null, result);
        }
    });
};


//// Sorted Sets
// add a member to the SortedSet
exports.zadd = internals.zadd = function (dataset, key, score, member, callback) {

    Hoek.assert(internals.redis, 'Connection not started');

    var setKey = internals.generateKey(dataset, key);

    internals.redis.zadd(setKey, score, member, function (err, result) {

        if (err) {
            console.error(err);
        }

        if (typeof callback === 'function') {
            if (err) {
                return callback(err);
            }

            return callback(null, result);
        }
    });
};


// add a member to the SortedSet and trim the size
exports.zaddtrim = internals.zaddtrim = function (dataset, key, score, member, callback) {

    Hoek.assert(internals.redis, 'Connection not started');

    var setKey = internals.generateKey(dataset, key);

    internals.redis
        .multi()
        .zadd(setKey, score, member)
        .zremrangebyrank(setKey, 0, dataset.size * -1)
        .exec(function (err, result) {

        if (typeof callback === 'function') {
            if (err) {
                return callback(err);
            }

            return callback(null, result);
        }
    });
};


// change the key of the member
exports.zchangekey = internals.zchangekey = function (dataset, oldkey, newKey, score, member, callback) {

    Hoek.assert(internals.redis, 'Connection not started');

    if (oldkey === newKey) {
        return callback(null, null);
    }

    oldkey = internals.generateKey(dataset, oldkey);
    newKey = internals.generateKey(dataset, newKey);

    internals.redis
        .multi()
        .zadd(newKey, score, member)
        .zremrangebyrank(newKey, 0, dataset.size * -1)
        .zrem(oldkey, member)
        .exec(function (err, result) {

        if (typeof callback === 'function') {
            if (err) {
                return callback(err);
            }

            return callback(null, result);
        }
    });
};


// Get the cardinality of the set
exports.zcard = internals.zcard = function (dataset, key, callback) {

    Hoek.assert(typeof callback === 'function', 'Invalid callback');
    Hoek.assert(internals.redis, 'Connection not started');

    var setKey = internals.generateKey(dataset, key);
    internals.redis.zcard(setKey, function (err, result) {

        if (err) {
            return callback(err);
        }

        return callback(null, result);
    });
};


// Get all the elements in the sorted set at key with a score between max and min
exports.zrevrangebyscore = internals.zrevrangebyscore = function (dataset, key, max, min, limit, callback) {

    Hoek.assert(typeof callback === 'function', 'Invalid callback');
    Hoek.assert(internals.redis, 'Connection not started');

    var setKey = internals.generateKey(dataset, key);
    internals.redis.zrevrangebyscore(setKey, max, min, 'LIMIT', 0, limit, function (err, result) {

        if (err) {
            return callback(err);
        }

        return callback(null, result);
    });
};


//// Hashes
exports.hset = internals.hset = function (dataset, key, field, value, callback) {

    Hoek.assert(internals.redis, 'Connection not started');

    var hashKey = internals.generateKey(dataset, key);
    internals.redis.hset(hashKey, field, value.toString(), function (err, result) {

        if (typeof callback === 'function') {
            if (err) {
                return callback(err);
            }

            return callback(null, result);
        }
    });
};


exports.hmset = internals.hmset = function (dataset, key, obj, callback) {

    Hoek.assert(internals.redis, 'Connection not started');

    var hashKey = internals.generateKey(dataset, key);
    internals.redis.hmset(hashKey, obj, function (err, result) {

        if (typeof callback === 'function') {
            if (err) {
                return callback(err);
            }

            return callback(null, result);
        }
    });
};


exports.hincrby = internals.hincrby = function (dataset, key, field, increment, callback) {

    Hoek.assert(internals.redis, 'Connection not started');

    var hashKey = internals.generateKey(dataset, key);
    internals.redis.hincrby(hashKey, field, increment, function (err, result) {

        if (typeof callback === 'function') {
            if (err) {
                return callback(err);
            }

            return callback(null, result);
        }
    });
};


exports.hgetall = internals.hgetall = function (dataset, key, callback) {

    Hoek.assert(typeof callback === 'function', 'Invalid callback');
    Hoek.assert(internals.redis, 'Connection not started');

    var hashKey = internals.generateKey(dataset, key);
    internals.redis.hgetall(hashKey, function (err, result) {

        if (err) {
            return callback(err);
        }

        return callback(null, result);
    });
};


exports.mhgetall = internals.hgetall = function (dataset, keys, callback) {

    Hoek.assert(typeof callback === 'function', 'Invalid callback');
    Hoek.assert(internals.redis, 'Connection not started');

    var pipeline = internals.redis.pipeline();

    _.each(keys, function (key) {
        var hashKey = internals.generateKey(dataset, key);
        pipeline.hgetall(hashKey);
    });

    pipeline.exec(function (err, results) {

        if (err) {
            return callback(err);
        }

        // Refer to https://github.com/luin/ioredis
        // result is an array, and each element is an array in form of: [err, value]
        return callback(null, results);
    });
};
