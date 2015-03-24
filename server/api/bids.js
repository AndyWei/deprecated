var Async = require('async');
var Boom = require('boom');
var Hoek = require('hoek');
var Joi = require('joi');
var c = require('../constants');

var internals = {};

exports.register = function (server, options, next) {

    options = Hoek.applyToDefaults({ basePath: '' }, options);

    // get a single bid by id. no auth.
    server.route({
        method: 'GET',
        path: options.basePath + '/bids/{id}',
        config: {
            validate: {
                params: {
                    id: Joi.string().regex(/^[0-9]+$/).max(19)
                }
            }
        },
        handler: function (request, reply) {

            var queryConfig = {
                name: 'bids_by_id',
                text: 'SELECT * FROM bids WHERE id = $1 AND deleted = false',
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


    // get all bids placed by the current user. auth.
    server.route({
        method: 'GET',
        path: options.basePath + '/bids/from_me',
        config: {
            auth: {
                strategy: 'token'
            }
        },
        handler: function (request, reply) {

            var userId = request.auth.credentials.id;
            var queryConfig = {
                name: 'bids_from_me',
                text: 'SELECT * FROM bids WHERE user_id = $1 AND deleted = false \
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


    // get all bids won by the current user. auth.
    server.route({
        method: 'GET',
        path: options.basePath + '/bids/won_by_me',
        config: {
            auth: {
                strategy: 'token'
            }
        },
        handler: function (request, reply) {

            var userId = request.auth.credentials.id;
            var queryConfig = {
                name: 'bids_won_by_me',
                text: 'SELECT * FROM bids WHERE user_id = $1 AND status >= 4 AND deleted = false \
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


    // Create an bid. auth.
    server.route({
        method: 'POST',
        path: options.basePath + '/bids',
        config: {
            auth: {
                strategy: 'token'
            },
            validate: {
                payload: {
                    order_id: Joi.string().regex(/^[0-9]+$/).max(19),
                    price: Joi.number().precision(2).min(0).max(100000000),
                    note: Joi.string().max(1000),
                    expire_at: Joi.number().min(0).default(0)
                }
            }
        },
        handler: internals.createBidHandler
    });


    // revoke a bid. auth.
    server.route({
        method: 'POST',
        path: options.basePath + '/bids/revoke/{bid_id}',
        config: {
            auth: {
                strategy: 'token'
            },
            validate: {
                params: {
                    bid_id: Joi.string().regex(/^[0-9]+$/).max(19)
                }
            }
        },
        handler: function (request, reply) {

            var queryConfig = {
                name: 'bids_revoke',
                text: 'UPDATE bids SET status = 1, updated_at = now() ' +
                      'WHERE id = $1 AND user_id = $2 AND status = 0 AND deleted = false ' +
                      'RETURNING id, status',
                values: [request.params.bid_id, request.auth.credentials.id]
            };

            request.pg.client.query(queryConfig, function (err, result) {

                if (err) {
                    return reply(err);
                }

                if (result.rows.length === 0) {
                    return reply(Boom.badRequest(c.BID_REVOKE_FAILED));
                }

                reply(null, result.rows[0]);
            });
        }
    });

    next();
};


exports.register.attributes = {
    name: 'bids'
};


internals.createBidHandler = function (request, reply) {

    Async.waterfall([
        function (callback) {

            var userId = request.auth.credentials.id;
            var p = request.payload;
            var queryConfig = {
                name: 'bids_create',
                text: 'INSERT INTO bids \
                           (user_id, order_id, price, note, expire_at, created_at, updated_at) VALUES \
                           ($1, $2, $3, $4, $5, now(), now()) \
                           RETURNING id',
                values: [userId, p.order_id, p.price, p.note, p.expire_at]
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
    ], function (err, bid) {

        if (err) {
            return reply(err);
        }

        reply(null, bid);
    });
};
