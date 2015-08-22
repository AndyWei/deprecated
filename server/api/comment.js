//  Copyright (c) 2015 Joyy Inc. All rights reserved.


var Async = require('async');
var Boom = require('boom');
var Cache = require('../cache');
var Hoek = require('hoek');
var Joi = require('joi');
var Const = require('../constants');
var Utils = require('../utils');
var _ = require('lodash');

var internals = {};
var select = 'SELECT id, owner, post, content, ct FROM comment ';

exports.register = function (server, options, next) {

    options = Hoek.applyToDefaults({ basePath: '' }, options);

    // get comment of a post. no auth.
    server.route({
        method: 'GET',
        path: options.basePath + '/comment',
        config: {
            validate: {
                query: {
                    post: Joi.string().regex(/^[0-9]+$/).max(19).required(),
                    after: Joi.number().default(0),
                    before: Joi.number().positive().default(Number.MAX_SAFE_INTEGER)
                }
            }
        },
        handler: function (request, reply) {

            var q = request.query;
            Async.waterfall([
                function (callback) {
                    Cache.zcard(Const.POST_COMMENT_SETS, q.post, function (err, result) {
                        if (err) {
                            console.error(err);
                            return callback(null, 0); // continue search in DB
                        }

                        return callback(null, result);
                    });
                },
                function (setSize, callback) {
                    if (setSize === 0) {
                         return callback(null, 0, null);
                    }

                    var min = '(' + q.after.toString();
                    var max = '(' + q.before.toString();
                    Cache.zrevrangebyscore(Const.POST_COMMENT_SETS, q.post, max, min, Const.COMMENT_PER_QUERY, function (err, result) {
                        if (err) {
                            console.error(err);
                            return callback(null, 0, null); // continue search in DB
                        }

                        return callback(null, setSize, result);
                    });
                },
                function (setSize, commentIds, callback) {
                    if (setSize === 0) {
                         return callback(null, 0, null, null); // continue search in DB
                    }

                    if (_.isEmpty(commentIds)) {
                        if (q.after !== 0 && q.before === Number.MAX_SAFE_INTEGER) { // try to fetch new but no more fresh post
                            return callback(null, setSize, null, []);                // just return empty result
                        }
                        else {                                                       // try to fetch old
                            return callback(null, 0, null, null);                    // search in DB
                        }
                    }

                    Cache.mhgetall(Const.COMMENT_HASHES, commentIds, function (err, result) {
                        if (err) {
                            console.error(err);
                        }

                        // result is an array, and each element is an array in form of [err, commentObj]
                        var foundObjs = _(result).map(_.last).compact().reject(_.isEmpty).value();
                        var foundIds = _.pluck(foundObjs, 'id');
                        var missedIds = _.difference(commentIds, foundIds);

                        return callback(null, setSize, missedIds, foundObjs);
                    });
                },
                function (setSize, missedIds, cachedObjs, callback) {
                    if (setSize === 0) {
                        internals.searchCommentByPostFromDB(request, function (err, result) {
                            return callback(null, result);
                        });
                    }
                    else if (_.isEmpty(missedIds)) {
                        return callback(null, cachedObjs);
                    }
                    else {
                        internals.searchCommentByIdsFromDB(request, missedIds, function (err, result) {

                            var mergedObjs = cachedObjs.concat(result);
                            var sortedObjs = _.sortBy(mergedObjs, function(comment) {
                                return comment.ct * -1;  // Sort records in DESC order by ct
                            });
                            return callback(null, sortedObjs);
                        });
                    }
                }
            ], function (err, results) {

                if (err) {
                    console.error(err);
                    return reply(err);
                }

                return reply(null, results);
            });
        }
    });


    // For each post in the query, get the last 3 comments of it from Cache. no auth.
    server.route({
        method: 'GET',
        path: options.basePath + '/comment/recent',
        config: {
            validate: {
                query: {
                    post: Joi.array().single(true).unique().items(Joi.string().regex(/^[0-9]+$/).max(19))
                }
            }
        },
        handler: function (request, reply) {

            var postIds = request.query.post;
            Async.auto({
                commentIds: function (callback) {

                    Cache.mzrange(Const.POST_COMMENT_SETS, postIds, -3, -1, function (err, result) {
                        if (err) {
                            console.error(err);
                        }

                        // result is an array whose every element is an array of commentId
                        return callback(null, result);
                    });
                },
                commentRecords: ['commentIds', function (callback, results) {

                    var commentIds = _.flatten(results.commentIds);

                    Cache.mhgetall(Const.COMMENT_HASHES, commentIds, function (err, result) {
                        if (err) {
                            console.error(err);
                        }

                        // result is an array whose every element is an array in form of [error, comment]
                        var validResult = _.filter(result, function (element) {
                            var error = element[0];
                            var comment = element[1];
                            return _.isNull(error) && !_.isNull(comment) && !_.isEmpty(comment);
                        });
                        var commentObjs = _.map(validResult, _.last);
                        var groupedObjs = _.groupBy(commentObjs, 'post');

                        return callback(null, groupedObjs);
                    });
                }]
            }, function (err, results) {

                if (err) {
                    return reply(err);
                }

                return reply(results.commentRecords);
            });
        }
    });


    // Create an comment. auth.
    server.route({
        method: 'POST',
        path: options.basePath + '/comment',
        config: {
            auth: {
                strategy: 'token'
            },
            validate: {
                payload: {
                    post: Joi.string().regex(/^[0-9]+$/).max(19).required(),
                    content: Joi.string().max(1000).required()
                }
            }
        },
        handler: internals.createCommentHandler
    });

    next();
};


internals.searchCommentByPostFromDB = function (request, callback) {

    var where = 'WHERE ct > $1 AND ct < $2 AND post = $3 AND deleted = false ';
    var order = 'ORDER BY ct DESC ';
    var limit = 'LIMIT 20';

    var queryValues = [request.query.after, request.query.before, request.query.post];
    var queryConfig = {
        name: 'comment_by_post',
        text: select + where + order + limit,
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


internals.searchCommentByIdsFromDB = function (request, commentIds, callback) {

    var parameterList = Utils.parametersString(3, commentIds.length);
    var where = 'WHERE ct > $1 AND ct < $2 AND deleted = false AND id in ' + parameterList; // Adding the min and max id is to speed up the where-in search
    var order = 'ORDER BY ct DESC ';
    var limit = 'LIMIT 20';

    var queryValues = [request.query.after, request.query.before];
    var queryConfig = {
        // Warning: DO NOT give a name to this query since it has variable parameters
        text: select + where + order + limit,
        values: queryValues.concat(commentIds)
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


internals.createCommentHandler = function (request, reply) {

    var p = request.payload;
    var postId = p.post;
    var ownerId = request.auth.credentials.id;

    Async.auto({
        comment: function (next) {

            var fields = 'INSERT INTO comment (owner, post, content, ct) ';
            var values = 'VALUES ($1, $2, $3, $4) RETURNING id';
            var createdAt = _.now();
            var queryConfig = {
                name: 'comment_create',
                text: fields + values,
                values: [ownerId, postId, p.content, createdAt]
            };

            request.pg.client.query(queryConfig, function (err, result) {

                if (err) {
                    request.pg.kill = true;
                    return next(err);
                }

                if (result.rows.length === 0) {
                    return next(Boom.badData(Const.COMMENT_CREATE_FAILED));
                }

                var commentId = result.rows[0].id;
                var commentObj = {
                    id: commentId,
                    owner: ownerId,
                    post: postId,
                    content: p.content,
                    ct: createdAt
                };

                Cache.hmset(Const.COMMENT_HASHES, commentId, commentObj);
                Cache.zaddtrim(Const.POST_COMMENT_SETS, postId, createdAt, commentId);

                return next(null, commentObj);
            });
        },
        post: ['comment', function (next) {

            var queryConfig = {
                name: 'post_comments',
                text: 'UPDATE post SET comments = comments + 1 ' +
                      'WHERE id = $1 AND deleted = false ' +
                      'RETURNING comments',
                values: [postId]
            };

            request.pg.client.query(queryConfig, function (err, result) {

                if (err) {
                    request.pg.kill = true;
                    return next(err);
                }

                if (result.rows.length === 0) {
                    return next(Boom.badRequest(Const.POST_LIKE_FAILED));
                }

                Cache.hincrby(Const.POST_HASHES, postId, 'comments', 1);

                return next(null, result.rows[0]);
            });
        }]
    }, function (err, results) {

        if (err) {
            console.error(err);
            return reply(err);
        }

        return reply(null, results.post);
    });
};


exports.register.attributes = {
    name: 'comment'
};

