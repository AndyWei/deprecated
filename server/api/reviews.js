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
                name: 'reviews_select_all_by_id',
                text: 'SELECT * FROM reviews WHERE id = $1 AND deleted = false',
                values: [request.params.id]
            };

            request.pg.client.query(queryConfig, function (err, result) {

                if (err) {
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
        path: options.basePath + '/reviews/my',
        config: {
            auth: {
                strategy: 'token'
            }
        },
        handler: function (request, reply) {

            var userId = request.auth.credentials.id;
            var queryConfig = {
                name: 'reviews_select_my',
                text: 'SELECT * FROM reviews WHERE reviewer_id = $1 AND deleted = false \
                       ORDER BY id DESC',
                values: [userId]
            };

            request.pg.client.query(queryConfig, function (err, result) {

                if (err) {
                    return reply(err);
                }

                reply(null, result.rows);
            });
        }
    });


    // get all reviews received by the user. no auth.
    server.route({
        method: 'GET',
        path: options.basePath + '/reviews/reviewee/{id}',
        config: {
            validate: {
                params: {
                    id: Joi.string().regex(/^[0-9]+$/).max(19)
                }
            }
        },
        handler: function (request, reply) {

            var queryConfig = {
                name: 'reviews_select_reviewee',
                text: 'SELECT * FROM reviews WHERE reviewee_id = $1 AND deleted = false \
                       ORDER BY id DESC',
                values: [request.params.id]
            };

            request.pg.client.query(queryConfig, function (err, result) {

                if (err) {
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
                    revieweeid: Joi.string().regex(/^[0-9]+$/).max(19),
                    rating: Joi.number().precision(2).min(0).max(5.0),
                    comment: Joi.string().max(1000)
                }
            }
        },
        handler: internals.createReviewHandler
    });

    next();
};


exports.register.attributes = {
    name: 'reviews'
};


internals.createReviewHandler = function (request, reply) {

    Async.waterfall([
        function (callback) {

            var userId = request.auth.credentials.id;
            var p = request.payload;
            var queryConfig = {
                name: 'reviews_create',
                text: 'INSERT INTO reviews \
                           (reviewer_id, reviewee_id, rating, comment, created_at, updated_at) VALUES \
                           ($1, $2, $3, $4, now(), now()) \
                           RETURNING id',
                values: [userId, p.revieweeid, p.rating, p.comment]
            };

            request.pg.client.query(queryConfig, function (err, result) {

                if (err) {
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
            return reply(err);
        }

        reply(null, review);
    });
};
