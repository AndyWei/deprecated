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
        path: options.basePath + '/bid/{id}',
        config: {
            validate: {
                params: {
                    id: Joi.string().regex(/^[0-9]+$/).max(19)
                }
            }
        },
        handler: function (request, reply) {

            var queryConfig = {
                name: 'bids_select_all_by_id',
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
        path: options.basePath + '/bids/my',
        config: {
            auth: {
                strategy: 'token'
            }
        },
        handler: function (request, reply) {

            var userId = request.auth.credentials.id;
            var queryConfig = {
                name: 'bids_select_my',
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
        path: options.basePath + '/bids/won',
        config: {
            auth: {
                strategy: 'token'
            }
        },
        handler: function (request, reply) {

            var userId = request.auth.credentials.id;
            var queryConfig = {
                name: 'bids_select_won',
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
        path: options.basePath + '/bid',
        config: {
            auth: {
                strategy: 'token'
            },
            validate: {
                payload: {
                    orderid: Joi.string().regex(/^[0-9]+$/).max(19),
                    price: Joi.number().precision(19),
                    description: Joi.string().max(1000)
                }
            }
        },
        handler: internals.createBidHandler
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
                           (user_id, order_id, offer_price, description, created_at, updated_at) VALUES \
                           ($1, $2, $3, $4, now(), now()) \
                           RETURNING id',
                values: [userId, p.orderid, p.price, p.description]
            };

            request.pg.client.query(queryConfig, function (err, result) {

                if (err) {
                    callback(err);
                }
                else if (result.rows.length === 0) {
                    callback(Boom.badData(c.QUERY_FAILED));
                }
                else {
                    callback(null, result.rows[0]);
                }
            });
        }
    ], function (err, bid) {

        if (err) {
            return reply(err);
        }

        reply(null, bid);
    });
};
