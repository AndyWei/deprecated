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


internals.generateKey = function (partition, localKey) {

    return String(partition.key) + String(localKey);
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
exports.drop = function (partition, key, callback) {

    Hoek.assert(internals.redis, 'Connection not started');

    internals.redis.del(internals.generateKey(partition, key), function (err) {

        if (typeof callback === 'function') {
            return callback(err);
        }
    });
};


exports.incr = function (partition, key, callback) {

    Hoek.assert(internals.redis, 'Connection not started');

    internals.redis.incr(internals.generateKey(partition, key), function (err, result) {

        if (typeof callback === 'function') {
            if (err) {
                return callback(err);
            }

            return callback(null, result);
        }
    });
};


exports.mget = function (partition, keys, callback) {

    Hoek.assert(typeof callback === 'function', 'Invalid callback');
    Hoek.assert(internals.redis, 'Connection not started');

    if (_.isUndefined(keys) || _.isNull(keys) || _.isEmpty(keys)) {
        return callback(null, []);
    }

    var cacheKeys = _.map(keys, function (key) {
        return internals.generateKey(partition, key);
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


exports.mset = function (partition, keys, values, callback) {

    Hoek.assert(internals.redis, 'Connection not started');

    var keyValues = _.map(keys, function (key, index) {

        var cacheKey = internals.generateKey(partition, key);
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


exports.setex = internals.setex = function (partition, key, value, callback) {

    Hoek.assert(internals.redis, 'Connection not started');

    var cacheKey = internals.generateKey(partition, key);
    value = value.toString();

    internals.redis.setex(cacheKey, partition.ttl, value, function (err) {

        if (typeof callback === 'function') {
            if (err) {
                return callback(err);
            }

            return callback(null);
        }
    });
};


exports.get = internals.get = function (partition, key, callback) {

    Hoek.assert(typeof callback === 'function', 'Invalid callback');
    Hoek.assert(internals.redis, 'Connection not started');

    var cacheKey = internals.generateKey(partition, key);
    internals.redis.get(cacheKey, function (err, result) {

        if (err) {
            return callback(err);
        }

        return callback(null, result);
    });
};


//// Lists
// Get all the elements from multi lists
exports.mgetlist = internals.mgetlist = function (partition, keys, callback) {

    Hoek.assert(typeof callback === 'function', 'Invalid callback');
    Hoek.assert(internals.redis, 'Connection not started');

    var pipeline = internals.redis.pipeline();

    _.each(keys, function (key) {
        var listKey = internals.generateKey(partition, key);
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
exports.getlist = internals.getlist = function (partition, key, callback) {

    Hoek.assert(typeof callback === 'function', 'Invalid callback');
    Hoek.assert(internals.redis, 'Connection not started');

    var listKey = internals.generateKey(partition, key);
    internals.redis.lrange(listKey, 0, -1, function (err, result) {

        if (err) {
            return callback(err);
        }

        return callback(null, result);
    });
};


exports.pushlist = internals.pushlist = function (partition, key, value, callback) {

    Hoek.assert(internals.redis, 'Connection not started');

    var listKey = internals.generateKey(partition, key);
    var pipeline = internals.redis.pipeline();

    pipeline
        .lpush(listKey, value)
        .ltrim(listKey, 0, partition.size - 1)
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
exports.zadd = internals.zadd = function (partition, key, score, member, callback) {

    Hoek.assert(internals.redis, 'Connection not started');

    var setKey = internals.generateKey(partition, key);

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


// add nulti members to the SortedSet
exports.mzadd = internals.mzadd = function (partition, key, scores, members, callback) {

    Hoek.assert(internals.redis, 'Connection not started');

    if (_.isUndefined(scores) || _.isNull(scores) || _.isEmpty(scores) ||
        _.isUndefined(members) || _.isNull(members) || _.isEmpty(members) ||
        !_.isArray(scores) || !_.isArray(members) || scores.count !== members.count) {

        console.err('The invalid scores or members');
        if (typeof callback === 'function') {
            return callback(null, []);
        }
        else
        {
            return null;
        }
    }

    var setKey = internals.generateKey(partition, key);
    var pipeline = internals.redis.pipeline();

    _.each(members, function (member, index) {
        var score = scores[index];
        pipeline.zadd(setKey, score, member);
    });

    pipeline.exec(function (err, result) {

        if (typeof callback === 'function') {
            if (err) {
                return callback(err);
            }

            return callback(null, result);
        }
    });
};


// get the specified range of elements in the sorted set stored at key
exports.zrange = internals.zrange = function (partition, key, start, stop, callback) {

    Hoek.assert(internals.redis, 'Connection not started');

    var setKey = internals.generateKey(partition, key);

    internals.redis.zrange(setKey, start, stop, function (err, result) {

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


// get the specified range of elements in the sorted set stored at keys
exports.mzrange = internals.mzrange = function (partition, keys, start, stop, callback) {

    Hoek.assert(typeof callback === 'function', 'Invalid callback');
    Hoek.assert(internals.redis, 'Connection not started');

    var pipeline = internals.redis.pipeline();

    _.each(keys, function (key) {
        var setKey = internals.generateKey(partition, key);
        pipeline.zrange(setKey, start, stop);
    });

    pipeline.exec(function (err, result) {

        if (err) {
            return callback(err);
        }

        // Refer to https://github.com/luin/ioredis
        // result is an array whose every element is an array in form of: [err, value]
        var values = _.map(result, _.last);

        return callback(null, values);
    });
};


// add a member to the SortedSet and trim the size
exports.zaddtrim = internals.zaddtrim = function (partition, key, score, member, callback) {

    Hoek.assert(internals.redis, 'Connection not started');

    var setKey = internals.generateKey(partition, key);

    internals.redis
        .multi()
        .zadd(setKey, score, member)
        .zremrangebyrank(setKey, 0, partition.size * -1)
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
exports.zchangekey = internals.zchangekey = function (partition, oldkey, newKey, score, member, callback) {

    Hoek.assert(internals.redis, 'Connection not started');

    if (oldkey === newKey) {
        return callback(null, null);
    }

    oldkey = internals.generateKey(partition, oldkey);
    newKey = internals.generateKey(partition, newKey);

    internals.redis
        .multi()
        .zadd(newKey, score, member)
        .zremrangebyrank(newKey, 0, partition.size * -1)
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
exports.zcard = internals.zcard = function (partition, key, callback) {

    Hoek.assert(typeof callback === 'function', 'Invalid callback');
    Hoek.assert(internals.redis, 'Connection not started');

    var setKey = internals.generateKey(partition, key);
    internals.redis.zcard(setKey, function (err, result) {

        if (err) {
            return callback(err);
        }

        return callback(null, result);
    });
};


// Get all the elements in the sorted set at key with a score between max and min
exports.zrevrangebyscore = internals.zrevrangebyscore = function (partition, key, max, min, limit, callback) {

    Hoek.assert(typeof callback === 'function', 'Invalid callback');
    Hoek.assert(internals.redis, 'Connection not started');

    var setKey = internals.generateKey(partition, key);
    internals.redis.zrevrangebyscore(setKey, max, min, 'LIMIT', 0, limit, function (err, result) {

        if (err) {
            return callback(err);
        }

        return callback(null, result);
    });
};


//// Hashes
exports.hset = internals.hset = function (partition, key, field, value, callback) {

    Hoek.assert(internals.redis, 'Connection not started');

    var hashKey = internals.generateKey(partition, key);
    internals.redis.hset(hashKey, field, value.toString(), function (err, result) {

        if (typeof callback === 'function') {
            if (err) {
                return callback(err);
            }

            return callback(null, result);
        }
    });
};


exports.hmset = internals.hmset = function (partition, key, obj, callback) {

    Hoek.assert(internals.redis, 'Connection not started');

    var hashKey = internals.generateKey(partition, key);
    internals.redis.hmset(hashKey, obj, function (err, result) {

        if (typeof callback === 'function') {
            if (err) {
                return callback(err);
            }

            return callback(null, result);
        }
    });
};


exports.mhmset = internals.mhmset = function (partition, keys, objs, callback) {

    Hoek.assert(internals.redis, 'Connection not started');

    if (_.isUndefined(keys) || _.isNull(keys) || _.isEmpty(keys) ||
        _.isUndefined(objs) || _.isNull(objs) || _.isEmpty(objs) ||
        !_.isArray(keys) || !_.isArray(objs) || keys.count !== objs.count) {

        console.err('The invalid keys or objs');
        if (typeof callback === 'function') {
            return callback(null, []);
        }
        else
        {
            return null;
        }
    }

    var hashKeys = _.map(keys, function (key) {
        return internals.generateKey(partition, key);
    });
    var pipeline = internals.redis.pipeline();

    _.each(hashKeys, function (hashKey, index) {
        pipeline.hmset(hashKey, objs[index]);
    });

    pipeline.exec(function (err, result) {

        if (typeof callback === 'function') {
            if (err) {
                return callback(err);
            }

            return callback(null, result);
        }
    });
};


exports.hincrby = internals.hincrby = function (partition, key, field, increment, callback) {

    Hoek.assert(internals.redis, 'Connection not started');

    var hashKey = internals.generateKey(partition, key);
    internals.redis.hincrby(hashKey, field, increment, function (err, result) {

        if (typeof callback === 'function') {
            if (err) {
                return callback(err);
            }

            return callback(null, result);
        }
    });
};


exports.hgetall = internals.hgetall = function (partition, key, callback) {

    Hoek.assert(typeof callback === 'function', 'Invalid callback');
    Hoek.assert(internals.redis, 'Connection not started');

    var hashKey = internals.generateKey(partition, key);
    internals.redis.hgetall(hashKey, function (err, result) {

        if (err) {
            return callback(err);
        }

        return callback(null, result);
    });
};


exports.mhgetall = internals.hgetall = function (partition, keys, callback) {

    Hoek.assert(typeof callback === 'function', 'Invalid callback');
    Hoek.assert(internals.redis, 'Connection not started');

    if (_.isUndefined(keys) || _.isNull(keys) || _.isEmpty(keys)) {
        return callback(null, []);
    }

    var pipeline = internals.redis.pipeline();

    _.each(keys, function (key) {
        var hashKey = internals.generateKey(partition, key);
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
