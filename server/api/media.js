var Async = require('async');
var AWS = require('aws-sdk');
var Boom = require('boom');
var Cache = require('../cache');
var Config = require('../../config');
var Hoek = require('hoek');
var Joi = require('joi');
var Long = require('long');
var c = require('../constants');
var _ = require('underscore');


var internals = {};

var selectClause = 'SELECT id, owner_id, media_type, path_version, filename, caption, created_at, \
                    ST_X(coordinate) AS lon, ST_Y(coordinate) AS lat \
                    FROM media ';

exports.register = function (server, options, next) {

    options = Hoek.applyToDefaults({ basePath: '' }, options);

    // config s3 region
    AWS.config.update({region: Config.get('/s3/region')});
    var bucketName = Config.get('/s3/bucketName');
    var bucket = new AWS.S3({params: {Bucket: bucketName}});
    var fileACL = Config.get('/s3/accessControlLevel');

    // get all media nearby. no auth.
    server.route({
        method: 'GET',
        path: options.basePath + '/media/nearby',
        config: {
            validate: {
                query: {
                    lon: Joi.number().min(-180).max(180).required(),
                    lat: Joi.number().min(-90).max(90).required(),
                    cell_id: Joi.string().max(12).required(),
                    distance: Joi.number().min(1).max(100).default(2),
                    after: Joi.string().regex(/^[0-9]+$/).max(19).default('0'),
                    before: Joi.string().regex(/^[0-9]+$/).max(19).default(c.MAX_ID)
                }
            }
        },
        handler: function (request, reply) {

            var q = request.query;
            Async.auto({
                fromCache: function (callback) {

                    Cache.getList(c.MEDIA_CACHE, q.cell_id, function (err, results) {
                        if (err) {
                            console.error(err);
                            return callback(null, null); // continue search in DB
                        }

                        var after = Long.fromString(q.after);
                        var before = Long.fromString(q.before);

                        // Note: media in results are DESC by mediaId
                        // quick check if we should search in DB
                        if (results.length === 0) {
                             return callback(null, null);
                        }

                        var lastResult = _.last(results);
                        var lastMedia = JSON.parse(lastResult);
                        var lastMediaId = Long.fromString(lastMedia[0]);
                        if (lastMediaId.greaterThanOrEqual(before)) {
                            return callback(null, null);
                        }

                        // Filter the results
                        var records = [];
                        for (i = 0, len = results.length; i < len; i++) {

                            var media = JSON.parse(results[i]); // [mediaId, ownerId, media_type, path_version, filename, caption, timestamp]
                            var mediaId = Long.fromString(media[0]);
                            results[i] = null; // release memory

                            if (mediaId.lessThanOrEqual(after)) {
                                break;
                            }

                            if (mediaId.lessThan(before)) {
                                var record = _.object(['id', 'owner_id', 'media_type', 'path_version', 'filename', 'caption', 'timestamp'], media);
                                media = null; // release memory
                                records.push(record);
                            }
                        }
                        results = null; // release memory

                        return callback('cacheHit', records);
                    });
                },
                fromDB: ['fromCache', function (callback) {

                    var degree = internals.degreeFromDistance(q.distance);

                    var where = 'WHERE id > $1 AND id < $2 AND ST_DWithin(coordinate, ST_SetSRID(ST_MakePoint($3, $4), 4326), $5) AND deleted = false ';
                    var order = 'ORDER BY id DESC ';
                    var limit = 'LIMIT 10';  // 10 media/request is a blance between search pressure and photo bandwidth usage

                    var queryValues = [q.after, q.before, q.lon, q.lat, degree];
                    var queryConfig = {
                        name: 'media_nearby',
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
                }]
            }, function (err, results) {

                // Check the results from cache
                if (err === 'cacheHit') {
                    return reply(null, results.fromCache);
                }

                if (err) {
                    console.error(err);
                    return reply(err);
                }

                return reply(null, results.fromDB);
            });
        }
    });

    // For each media id in the query, get its like count, comment count and last 3 comments. no auth.
    server.route({
        method: 'GET',
        path: options.basePath + '/media/brief',
        config: {
            validate: {
                query: {
                    id: Joi.array().single(true).unique().items(Joi.string().regex(/^[0-9]+$/).max(19))
                }
            }
        },
        handler: function (request, reply) {

            var mediaIds = request.query.id;

            Async.auto({
                commentLists: function (callback) {

                    Cache.mgetList(c.COMMENT_CACHE, mediaIds, function (err, result) {
                        if (err) {
                            console.error(err);
                        }
                        return callback(null, result);
                    });
                },
                commentCounts: function (callback) {

                    Cache.mget(c.COMMENT_COUNT_CACHE, mediaIds, function (err, result) {
                        if (err) {
                            console.error(err);
                        }
                        return callback(null, result);
                    });
                },
                likeCounts: function (callback) {

                    Cache.mget(c.LIKE_COUNT_CACHE, mediaIds, function (err, result) {
                        if (err) {
                            console.error(err);
                        }
                        return callback(null, result);
                    });
                }/*,  In case of cache missed, query from DB
                countFromDB: ['countFromCache', function (callback) {

                }],
                contentFromDB: ['contentFromCache', function (callback) {

                }]*/
            }, function (err, results) {

                if (err) {
                    return reply(err);
                }

                // results.mediaIds      = ['4', '3', '2', '1']
                // results.likeCounts    = [null, null, null, null]
                // results.commentCounts = [null, null, null, '2']
                // results.commentLists  = [[], [], [], ['second comment','some comment contents']]
                var commentLists = _.map(results.commentLists, function (commentList) {
                    return commentList.reverse();
                });
                //commentLists  = [[], [], [], ['some comment contents', 'second comment']]
                results.commentLists = null; // release memory

                var itemArray = _.zip(mediaIds, results.likeCounts, results.commentCounts, commentLists);
                /*
                 *  itemArray = [
                 *      ['4', null, null, []],
                 *      ['3', null, null, []],
                 *      ['2', null, null, []],
                 *      ['1', null, '2', ['some comment contents', 'second comment']]
                 *  ]
                 */
                var objectArray = _.map(itemArray, function (item) {
                    return _.object(['id', 'like_count', 'comment_count', 'comment_list'], item);
                });
                /*
                 *  objectArray = [
                 *      {'id': '4', 'like_count': null, 'comment_count': null, 'comment_list': []},
                 *      {'id': '3', 'like_count': null, 'comment_count': null, 'comment_list': []},
                 *      {'id': '2', 'like_count': null, 'comment_count': null, 'comment_list': []},
                 *      {'id': '1', 'like_count': null, 'comment_count':  '2', 'comment_list': ['some comment contents', 'second comment']}
                 *  ]
                */
                itemArray = null; // release memory
                return reply(objectArray);
            });
        }
    });

    // upload a media. auth.
    server.route({
        method: 'POST',
        path: options.basePath + '/media',
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
                    media_type: Joi.number().min(0).max(2).required(),
                    caption: Joi.string().max(2000).required(),
                    cell_id: Joi.string().max(12).required()
                }
            }
        },
        handler: function (request, reply) {

            var ownerId = request.auth.credentials.id;
            var p = request.payload;
            var dbFilename = p.file.hapi.filename;
            var s3Filename = p.file.hapi.filename + '.jpg';

            if (!dbFilename) {
                return reply(Boom.badData(c.FILENAME_MISSING));
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

                    var fields = 'INSERT INTO media (owner_id, media_type, path_version, filename, caption, coordinate, created_at) ';
                    var values = 'VALUES ($1, $2, $3, $4, $5, ST_SetSRID(ST_MakePoint($6, $7), 4326), now()) RETURNING id';
                    var queryValues = [ownerId, p.media_type, 0, dbFilename, p.caption, p.lon, p.lat];

                    var queryConfig = {
                        name: 'media_create',
                        text: fields + values,
                        values: queryValues
                    };

                    request.pg.client.query(queryConfig, function (err, result) {

                        if (err) {
                            request.pg.kill = true;
                            return reply(err);
                        }

                        if (result.rows.length === 0) {
                            return reply(Boom.badRequest(c.MEDIA_CREATE_FAILED));
                        }

                        return callback(null, result.rows[0].id);
                    });
                },
                function (mediaId, callback) {

                    var mediaRecord = JSON.stringify([mediaId, ownerId, p.media_type, 0, dbFilename, p.caption, _.now()]);
                    // push the media record to cache and increase the media count
                    Cache.enqueue(c.MEDIA_CACHE, c.MEDIA_COUNT_CACHE, p.cell_id, mediaRecord, function (error) {
                        if (error) {
                            // Just log the error, do not call next(error) since caching is a kind of "try our best" thing
                            console.error(error);
                        }

                        return callback(null, mediaId);
                    });
                }
            ], function (err, mediaId) {

                if (err) {
                    console.error(err);
                    return reply(err);
                }

                return reply(null, {id: mediaId});
            });
        }
    });


    // like a media. auth.
    server.route({
        method: 'POST',
        path: options.basePath + '/media/like',
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

            // push this comment content to cache and increase the comment count
            Cache.incr(c.LIKE_COUNT_CACHE, request.payload.id, function (err, result) {
                if (err) {
                    // Just log the error, do not call next(err) since caching is a kind of "try our best" thing
                    console.error(err);
                }

                return reply(null, {'like_count': result});
            });
        }
    });


    next();
};


/*
 *  convert distance in km to GPS degree
 */
internals.degreeFromDistance = function(distance) {

    return distance * c.DEGREE_FACTOR;
};


exports.register.attributes = {
    name: 'media'
};
