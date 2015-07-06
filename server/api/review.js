var Async = require('async');
var Boom = require('boom');
var Hoek = require('hoek');
var Joi = require('joi');
var c = require('../constants');

var internals = {};

exports.register = function (server, options, next) {

    options = Hoek.applyToDefaults({ basePath: '' }, options);

    // get a single review by id. no auth.
    server.route({
        method: 'GET',
        path: options.basePath + '/review/{id}',
        config: {
            validate: {
                params: {
                    id: Joi.string().regex(/^[0-9]+$/).max(19)
                }
            }
        },
        handler: function (request, reply) {

            var queryConfig = {
                name: 'review_by_id',
                text: 'SELECT * FROM review WHERE id = $1 AND deleted = false',
                values: [request.params.id]
            };

            request.pg.client.query(queryConfig, function (err, result) {

                if (err) {
                    console.error(err);
                    request.pg.kill = true;
                    return reply(err);
                }

                if (result.rows.length === 0) {
                    return reply(Boom.notFound(c.RECORD_NOT_FOUND));
                }

                reply(null, result.rows[0]);
            });
        }
    });


    // get all reviews provided by the current user. auth.
    server.route({
        method: 'GET',
        path: options.basePath + '/review/from_me',
        config: {
            auth: {
                strategy: 'token'
            }
        },
        handler: function (request, reply) {

            var userId = request.auth.credentials.id;
            var queryConfig = {
                name: 'review_from_me',
                text: 'SELECT * FROM review WHERE reviewer_id = $1 AND deleted = false \
                       ORDER BY id DESC',
                values: [userId]
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


    // get all review received by the user. no auth.
    server.route({
        method: 'GET',
        path: options.basePath + '/review/of/{id}',
        config: {
            validate: {
                params: {
                    id: Joi.string().regex(/^[0-9]+$/).max(19)
                }
            }
        },
        handler: function (request, reply) {

            var queryConfig = {
                name: 'review_of',
                text: 'SELECT * FROM review WHERE reviewee_id = $1 AND deleted = false \
                       ORDER BY id DESC',
                values: [request.params.id]
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


    // Create an review. auth.
    server.route({
        method: 'POST',
        path: options.basePath + '/review',
        config: {
            auth: {
                strategy: 'token'
            },
            validate: {
                payload: {
                    reviewee_id: Joi.string().regex(/^[0-9]+$/).max(19),
                    order_id: Joi.string().regex(/^[0-9]+$/).max(19),
                    rating: Joi.number().precision(2).min(0).max(5.0),
                    body: Joi.string().max(1000)
                }
            }
        },
        handler: internals.createReviewHandler
    });

    next();
};


exports.register.attributes = {
    name: 'review'
};


internals.createReviewHandler = function (request, reply) {

    Async.waterfall([
        function (callback) {

            var userId = request.auth.credentials.id;
            var p = request.payload;
            var queryConfig = {
                name: 'review_create',
                text: 'INSERT INTO review \
                           (reviewer_id, reviewee_id, order_id, rating, body, created_at, updated_at) VALUES \
                           ($1, $2, $3, $4, $5, now(), now()) \
                           RETURNING id',
                values: [userId, p.reviewee_id, p.order_id, p.rating, p.body]
            };

            request.pg.client.query(queryConfig, function (err, result) {

                if (err) {
                    request.pg.kill = true;
                    return callback(err);
                }

                if (result.rows.length === 0) {
                    return callback(Boom.badData(c.QUERY_FAILED));
                }

                callback(null, result.rows[0]);
            });
        }
    ], function (err, review) {

        if (err) {
            console.error(err);
            return reply(err);
        }

        reply(null, review);
    });
};
