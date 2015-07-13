var Async = require('async');
var AWS = require('aws-sdk');
var Boom = require('boom');
var Config = require('../../config');
var Hoek = require('hoek');
var Joi = require('joi');
var c = require('../constants');

var internals = {};

var selectClause = 'SELECT id, user_id, media_type, path_version, filename, caption, created_at, updated_at, \
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
            var limit = 'LIMIT 20';

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

                reply(null, result.rows);
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
                    caption: Joi.string().max(1000).required()
                }
            }
        },
        handler: function (request, reply) {

            var p = request.payload;
            var filename = p.file.hapi.filename;

            if (!filename) {
                return reply(Boom.badData(c.FILENAME_MISSING));
            }

            Async.waterfall([
                function (callback) {

                    var params = {Key: filename, Body: p.file, ACL: fileACL};

                    bucket.upload(params, function (err, data) {

                        if (err) {
                            return callback(err);
                        }

                        console.log('uploaded file success. s3 url = ', data.Location);

                        callback(null);
                    });
                },
                function (callback) {

                    var u = request.auth.credentials;
                    var fields = 'INSERT INTO media (user_id, media_type, path_version, filename, caption, coordinate, created_at, updated_at) ';
                    var values = 'VALUES ($1, $2, $3, $4, $5, ST_SetSRID(ST_MakePoint($6, $7), 4326), now(), now()) RETURNING id';
                    var queryValues = [u.id, p.media_type, 0, filename, p.caption, p.lon, p.lat];

                    var queryConfig = {
                        name: 'media_create',
                        text: fields + values,
                        values: queryValues
                    };

                    request.pg.client.query(queryConfig, function (err, result) {

                        if (err) {
                            console.error(err);
                            request.pg.kill = true;
                            return reply(err);
                        }

                        if (result.rows.length === 0) {
                            return reply(Boom.badRequest(c.MEDIA_CREATE_FAILED));
                        }

                        callback(null, result.rows[0]);
                    });
                }
            ], function (err, media_id) {

                if (err) {
                    console.error(err);
                    return reply(err);
                }

                reply(null, media_id);
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
