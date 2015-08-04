var Async = require('async');
var AWS = require('aws-sdk');
var Boom = require('boom');
var Cache = require('../cache');
var Config = require('../../config');
var Const = require('../constants');
var Hoek = require('hoek');
var Joi = require('joi');
var Utils = require('../utils');
var _ = require('underscore');

var internals = {};
var selectClause = 'SELECT id, owner, type, uv, filename, caption, likes, comments, ct FROM post ';


exports.register = function (server, options, next) {

    options = Hoek.applyToDefaults({ basePath: '' }, options);

    // config s3 region
    AWS.config.update({region: Config.get('/s3/region')});
    var bucketName = Config.get('/s3/bucketName');
    var bucket = new AWS.S3({params: {Bucket: bucketName}});
    var fileACL = Config.get('/s3/accessControlLevel');

    // get post in the cell. no auth.
    server.route({
        method: 'GET',
        path: options.basePath + '/post/nearby',
        config: {
            validate: {
                query: {
                    cell: Joi.string().max(12).required(),
                    after: Joi.number().default(0),
                    before: Joi.number().positive().default(Number.MAX_SAFE_INTEGER)
                }
            }
        },
        handler: function (request, reply) {

            var q = request.query;
            Async.waterfall([
                function (callback) {
                    Cache.zcard(Const.CELL_POST_SETS, q.cell, function (err, result) {
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
                    Cache.zrevrangebyscore(Const.CELL_POST_SETS, q.cell, max, min, Const.POST_LIMIT, function (err, result) {
                        if (err) {
                            console.error(err);
                            return callback(null, 0, null); // continue search in DB
                        }

                        return callback(null, setSize, result);
                    });
                },
                function (setSize, postIds, callback) {
                    if (setSize === 0) {
                         return callback(null, 0, null, null); // continue search in DB
                    }

                    if (_.isEmpty(postIds)) {
                        if (q.after !== 0 && q.before === Number.MAX_SAFE_INTEGER) { // try to fetch new but no more fresh post
                            return callback(null, setSize, null, []);                // just return empty result
                        }
                        else {                                                       // try to fetch old
                            return callback(null, 0, null, null);                    // search in DB
                        }
                    }

                    Cache.mhgetall(Const.POST_HASHES, postIds, function (err, result) {
                        if (err) {
                            console.error(err);
                        }

                        var missedPostIds = [];
                        var foundPost = [];
                        for (var i = 0; i < postIds.length; i++) {
                            // result is an array, and each element is an array in form of [err, postObj]
                            if (result[i][0]) {  // found err
                                missedPostIds.push(postIds[i]);
                            }
                            else {
                                foundPost.push(result[i][1]);
                            }
                        }

                        return callback(null, setSize, missedPostIds, foundPost);
                    });
                },
                function (setSize, missedPostIds, foundPost, callback) {
                    if (setSize === 0) {
                        internals.searchPostByCellFromDB(request, function (err, result) {
                            return callback(null, result);
                        });
                    }
                    else if (_.isNull(missedPostIds) || _.isEmpty(missedPostIds)) {
                        return callback(null, foundPost);
                    }
                    else {
                        internals.searchPostByIdsFromDB(request, missedPostIds, function (err, result) {

                            var merged = foundPost.concat(result);
                            var sorted = _.sortBy(merged, function(post) {
                                return post.ct * -1;  // Sort records in DESC order by ct
                            });
                            return callback(null, sorted);
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


    // For each post id in the query, get its like count, comment count and last 3 comments. no auth.
    server.route({
        method: 'GET',
        path: options.basePath + '/post/brief',
        config: {
            validate: {
                query: {
                    id: Joi.array().single(true).unique().items(Joi.string().regex(/^[0-9]+$/).max(19))
                }
            }
        },
        handler: function (request, reply) {

            var postIds = request.query.id;

            Async.auto({
                commentListsfromCache: function (callback) {

                    Cache.mgetlist(Const.POST_COMMENT_LISTS, postIds, function (err, result) {
                        if (err) {
                            console.error(err);
                        }

                        var postBriefArray = _.map(result, function (commentList, index) {
                            return _.object(['id', 'comment_list'], [postIds[index], commentList.reverse()]);
                        });
                        return callback(null, postBriefArray);
                    });
                }/*,  In case of cache missed, query from DB
                commentListsfromDB: ['commentListsfromCache', function (callback) {

                }]*/
            }, function (err, results) {

                if (err) {
                    return reply(err);
                }

                return reply(results.commentListsfromCache);
            });
        }
    });


    // upload a post. auth.
    server.route({
        method: 'POST',
        path: options.basePath + '/post',
        config: {
            auth: {
                strategy: 'token'
            },
            payload: {
                maxBytes: 1048576, // Hapi default is 1MB
                output: 'stream',
                parse: true
            },
            validate: {
                payload: {
                    lon: Joi.number().min(-180).max(180).required(),
                    lat: Joi.number().min(-90).max(90).required(),
                    file: Joi.any().required(),
                    type: Joi.number().min(0).max(2).required(),
                    caption: Joi.string().max(900).required(),
                    cell: Joi.string().max(12).required()
                }
            }
        },
        handler: function (request, reply) {

            var ownerId = request.auth.credentials.id;
            var p = request.payload;
            var dbFilename = p.file.hapi.filename;
            var s3Filename = p.file.hapi.filename + '.jpg';

            if (!dbFilename) {
                return reply(Boom.badData(Const.FILENAME_MISSING));
            }

            Async.waterfall([
                function (callback) {

                    var params = {Key: s3Filename, Body: p.file, ACL: fileACL};

                    bucket.upload(params, function (err, data) {

                        if (err) {
                            return callback(err);
                        }

                        console.log('uploaded file success. s3 url = ', data.Location);

                        return callback(null);
                    });
                },
                function (callback) {

                    var fields = 'INSERT INTO post (owner, type, uv, filename, caption, coords, cell, ct) ';
                    var values = 'VALUES ($1, $2, $3, $4, $5, ST_SetSRID(ST_MakePoint($6, $7), 4326), $8, $9) RETURNING id';
                    var createdAt = _.now();
                    var queryValues = [ownerId, p.type, 0, dbFilename, p.caption, p.lon, p.lat, p.cell, createdAt];

                    var queryConfig = {
                        name: 'post_create',
                        text: fields + values,
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

                        return callback(null, result.rows[0].id, createdAt);
                    });
                },
                function (postId, createdAt, callback) {

                    var postObj = {
                        id: postId,
                        owner: ownerId,
                        type: p.type,
                        uv: 0,
                        filename: dbFilename,
                        caption: p.caption,
                        likes: 0,
                        comments: 0,
                        ct: createdAt
                    };

                    Cache.hmset(Const.POST_HASHES, postId, postObj);
                    Cache.zaddtrim(Const.CELL_POST_SETS, p.cell, createdAt, postId);
                    callback(null, postObj);
                }
            ], function (err, postObj) {

                if (err) {
                    console.error(err);
                    return reply(err);
                }

                return reply(null, postObj);
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
                name: 'post_like',
                text: 'UPDATE post SET likes = likes + 1 ' +
                      'WHERE id = $1 AND deleted = false ' +
                      'RETURNING likes',
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

                Cache.hincrby(Const.POST_HASHES, request.payload.id, 'likes', 1);

                return reply(null, result.rows[0]);
            });
        }
    });

    next();
};


internals.searchPostByCellFromDB = function (request, callback) {

    var where = 'WHERE ct > $1 AND ct < $2 AND cell = $3 AND deleted = false ';
    var order = 'ORDER BY ct DESC ';
    var limit = 'LIMIT 20';

    var queryValues = [request.query.after, request.query.before, request.query.cell];
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


exports.register.attributes = {
    name: 'post'
};


internals.searchPostByIdsFromDB = function (request, postIds, callback) {

    var parameterList = Utils.parametersString(3, postIds.length);
    var where = 'WHERE ct > $1 AND ct < $2 AND deleted = false AND id in ' + parameterList; // Adding the min and max id is to speed up the where-in search
    var order = 'ORDER BY ct DESC ';
    var limit = 'LIMIT 20';

    var queryValues = [request.query.after, request.query.before];
    var queryConfig = {
        name: 'post_by_ids',
        text: selectClause + where + order + limit,
        values: queryValues.concat(postIds)
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
