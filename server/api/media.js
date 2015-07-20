var Async = require('async');
var AWS = require('aws-sdk');
var Boom = require('boom');
var Cache = require('../cache');
var Config = require('../../config');
var Hoek = require('hoek');
var Joi = require('joi');
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
                    distance: Joi.number().min(1).max(100).default(2),
                    after: Joi.string().regex(/^[0-9]+$/).max(19).default('0'),
                    before: Joi.string().regex(/^[0-9]+$/).max(19).default('9223372036854775807')
                }
            }
        },
        handler: function (request, reply) {

            var q = request.query;
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
                    return reply(err);
                }

                return reply(null, result.rows);
            });
        }
    });

    // For each media_id in the query, get its like count, comment count and last 3 comments. no auth.
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

                // mediaIds      = ['4', '3', '2', '1']
                // likeCounts    = [null, null, null, null]
                // commentCounts = [null, null, null, '2']
                // commentLists  = [[], [], [], ['second comment','some comment contents']]

                var itemArray = _.zip(mediaIds, results.likeCounts, results.commentCounts, results.commentLists);
                /*
                 *  itemArray = [
                 *      ['4', null, null, []],
                 *      ['3', null, null, []],
                 *      ['2', null, null, []],
                 *      ['1', null, '2', ['second comment','some comment contents']]
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
                 *      {'id': '1', 'like_count': null, 'comment_count':  '2', 'comment_list': ['second comment','some comment contents']}
                 *  ]
                */

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
                    caption: Joi.string().max(2000).required()
                }
            }
        },
        handler: function (request, reply) {

            var p = request.payload;
            var dbFilename = p.file.hapi.filename;
            var s3Filename = p.file.hapi.filename + '.jpg';

            if (!filename) {
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

                    var u = request.auth.credentials;
                    var fields = 'INSERT INTO media (owner_id, media_type, path_version, filename, caption, coordinate, created_at) ';
                    var values = 'VALUES ($1, $2, $3, $4, $5, ST_SetSRID(ST_MakePoint($6, $7), 4326), now()) RETURNING id';
                    var queryValues = [u.id, p.media_type, 0, dbFilename, p.caption, p.lon, p.lat];

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

                        return callback(null, result.rows[0]);
                    });
                }
            ], function (err, media_id) {

                if (err) {
                    console.error(err);
                    return reply(err);
                }

                return reply(null, media_id);
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
