//  Copyright (c) 2015 Joyy Inc. All rights reserved.


var Async = require('async');
var Boom = require('boom');
var Cache = require('../cache');
var Const = require('../constants');
var Hoek = require('hoek');
var Joi = require('joi');
var _ = require('lodash');

var internals = {};
var selectClause = 'SELECT id, owner, url, caption, lcnt, ccnt, ct FROM post ';


exports.register = function (server, options, next) {

    options = Hoek.applyToDefaults({ basePath: '' }, options);

    // get posts from the cell that mapped by the zip. no auth.
    server.route({
        method: 'GET',
        path: options.basePath + '/post/nearby',
        config: {
            validate: {
                query: {
                    zip: Joi.string().min(2).max(14).required(), // E.g., US94555
                    after: Joi.number().min(0).max(Number.MAX_SAFE_INTEGER).default(0),
                    before: Joi.number().min(0).max(Number.MAX_SAFE_INTEGER).default(Number.MAX_SAFE_INTEGER)
                }
            }
        },
        handler: function (request, reply) {

            var r = request.query;
            Async.auto({
                cell: function (callback) {

                    var readonly = true;
                    internals.getPostCellFromZip(r.zip, readonly, function (err, result) {
                        if (err) {
                            return callback(err);
                        }

                        return callback(null, result);
                    });
                },
                cache: ['cell', function (callback, results) {

                    internals.searchPostFromCache(request, results.cell, function (err, result) {

                        if (err === Const.SKIP_DB_SEARCH) {
                            return callback(Const.SKIP_DB_SEARCH);
                        }

                        if (err === Const.CACHE_MISS) {
                            return callback(null);
                        }

                        return callback(Const.CACHE_HIT, result);
                    });
                }],
                db: ['cache', function (callback, results) {

                    internals.searchPostByCellFromDB(request, results.cell, function (err, result) {
                        return callback(null, result);
                    });
                }]
            }, function (err, results) {

                if (err === Const.CACHE_HIT) {
                    return reply(null, results).cache;
                }
                if (err) {
                    console.error(err);
                    return reply(err);
                }

                return reply(null, results.db);
            });
        }
    });


    // create a post. auth.
    server.route({
        method: 'POST',
        path: options.basePath + '/post',
        config: {
            auth: {
                strategy: 'token'
            },
            validate: {
                payload: {
                    url: Joi.string().required(),
                    caption: Joi.string().max(900).required(),
                    zip: Joi.string().min(2).max(14).required() // E.g., US94555
                }
            }
        },
        handler: function (request, reply) {

            var ownerId = request.auth.credentials.id;
            var r = request.payload;

            Async.auto({
                post: function (callback) {

                    var insert = 'INSERT INTO post (owner, url, caption, zip, ct) ';
                    var values = 'VALUES ($1, $2, $3, $4, $5) RETURNING id, ct';
                    var queryValues = [ownerId, r.url, r.caption, r.zip, _.now()];

                    var queryConfig = {
                        name: 'post_create',
                        text: insert + values,
                        values: queryValues
                    };

                    request.pg.client.query(queryConfig, function (err, result) {

                        if (err) {
                            request.pg.kill = true;
                            return reply(err);
                        }

                        if (result.rows.length === 0) {
                            return reply(Boom.badRequest(Const.POST_CREATE_FAILED));
                        }

                        return callback(null, result.rows[0]);
                    });
                },
                cell: function (callback) {

                    var readonly = false;
                    internals.getPostCellFromZip(r.zip, readonly, function (err, result) {
                        if (err) {
                            return callback(err);
                        }

                        return callback(null, result);
                    });
                },
                cache: ['post', 'cell', function (callback, results) {

                    var postId = results.post.id.toString();
                    var createdAt = results.post.ct;
                    var postObj = {
                        id: postId,
                        owner: ownerId,
                        url: r.url,
                        caption: r.caption,
                        ct: createdAt
                    };

                    Cache.hmset(Cache.PostStore, postId, postObj);
                    Cache.zaddtrim(Cache.PostsInCell, results.cell, createdAt, postId);
                    callback(null, postObj);
                }]
            }, function (err, results) {

                if (err) {
                    console.error(err);
                    return reply(err);
                }

                return reply(null, results.cache);
            });
        }
    });


    // like a post. auth.
    server.route({
        method: 'POST',
        path: options.basePath + '/post/like',
        config: {
            auth: {
                strategy: 'token'
            },
            validate: {
                payload: {
                    id: Joi.string().regex(/^[0-9]+$/).max(19).required()
                }
            }
        },
        handler: function (request, reply) {

            var postId = request.payload.id;
            var queryConfig = {
                name: 'post_lcnt',
                text: 'UPDATE post SET lcnt = lcnt + 1 ' +
                      'WHERE id = $1 AND deleted = false ' +
                      'RETURNING lcnt',
                values: [postId]
            };

            request.pg.client.query(queryConfig, function (err, result) {

                if (err) {
                    request.pg.kill = true;
                    return reply(err);
                }

                if (result.rows.length === 0) {
                    return reply(Boom.badRequest(Const.POST_LIKE_FAILED));
                }

                Cache.hincrby(Cache.PostStore, postId, 'lcnt', 1);

                return reply(null, result.rows[0]);
            });
        }
    });

    next();
};


internals.searchPostFromCache = function (request, cell, reply) {

    var r = request.query;
    Async.auto({
        postIds: function (callback) {

            var min = '(' + r.after.toString();
            var max = '(' + r.before.toString();
            Cache.zrevrangebyscore(Cache.PostsInCell, cell, max, min, Const.POST_PER_QUERY, function (err, result) {
                if (err) {
                    return callback(err);
                }

                return callback(null, result);
            });
        },
        posts: ['postIds', function (callback, results) {

            if (_.isEmpty(results.postIds)) {
                if (r.after !== 0 && r.before === Number.MAX_SAFE_INTEGER) { // try to fetch new but no more fresh post
                    return callback(Const.SKIP_DB_SEARCH);                   // just skip DB search and return empty result
                }
                else {                                                       // try to fetch old posts, allow DB search
                    return callback(Const.CACHE_MISS);
                }
            }

            Cache.mhgetall(Cache.PostStore, results.postIds, function (err, result) {
                if (err) {
                    return callback(err);
                }

                // result is an array, and each element is an array in form of [err, postObj]
                var foundObjs = _(result).map(_.last).compact().reject(_.isEmpty).value();

                return callback(null, foundObjs);
            });
        }]
    }, function (err, results) {

        if (err) {
            return reply(err);
        }

        return reply(null, results.posts);
    });
};


internals.searchPostByCellFromDB = function (request, cell, callback) {

    var where = 'WHERE ct > $1 AND ct < $2 AND position($3 in zip) = 1 AND deleted = false ';
    var order = 'ORDER BY ct DESC ';
    var limit = 'LIMIT 20';

    var queryValues = [request.query.after, request.query.before, cell];
    var queryConfig = {
        name: 'post_by_cell',
        text: selectClause + where + order + limit,
        values: queryValues
    };

    request.pg.client.query(queryConfig, function (err, result) {

        if (err) {
            console.error(err);
            request.pg.kill = true;
            return callback(err);
        }

        return callback(null, result.rows);
    });
};


internals.getPostCellFromZip = function (zip, readonly, reply) {

    var splitIndex = zip.length - 3;
    var zipPrefix = zip.substring(0, splitIndex);
    var zipSuffix = zip.substring(splitIndex);

    Async.auto({

        cell: function (callback) {

            Cache.hget(Cache.ZipCellMap, zipPrefix, zipSuffix, function (err, result) {
                if (err) {
                    return callback(err);
                }

                var cell = result;
                if (!cell) {
                    cell = zip.substr(0, 2); // Use CountryCode as default cells, e.g., 'US'
                }

                if (readonly) {
                    return callback(Const.CACHE_HIT, cell);
                }

                return callback(null, cell);
            });
        },
        postCount: ['cell', function (callback, results) {

            Cache.zcard(Cache.PostsInCell, results.cell, function (err, result) {
                if (err) {
                    return callback(err);
                }

                return callback(null, result);
            });
        }],
        splitCell: ['postCount', function (callback, results) {

            var newCell = results.cell;
            if (results.postCount > Const.POST_CELL_SPLIT_THRESHOLD) {

                newCell = zip.substr(0, newCell.length + 1); // Use one more letter as new cell
                Cache.hset(Cache.ZipCellMap, zipPrefix, zipSuffix, newCell);
            }
            return callback(null, newCell);
        }]
    }, function (err, results) {

        if (err === Const.CACHE_HIT) {
            return reply(null, results.cell);
        }

        if (err) {
            console.error(err);
            return reply(err);
        }

        return reply(null, results.splitCell);
    });
};


exports.register.attributes = {
    name: 'post'
};

