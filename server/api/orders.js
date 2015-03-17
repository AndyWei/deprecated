var Async = require('async');
var Boom = require('boom');
var Hoek = require('hoek');
var Joi = require('joi');
var c = require('../constants');

var internals = {};

exports.register = function (server, options, next) {

    options = Hoek.applyToDefaults({ basePath: '' }, options);

    // get a single order by id. no auth.
    server.route({
        method: 'GET',
        path: options.basePath + '/order/{id}',
        config: {
            validate: {
                params: {
                    id: Joi.string().regex(/^[0-9]+$/).max(19)
                }
            }
        },
        handler: function (request, reply) {

            var queryConfig = {
                text: 'SELECT id, uid, initial_price, final_price, currency, country, status, created_at, description, address, ST_X(venue) AS lon, ST_Y(venue) AS lat \
                       FROM orders WHERE id = $1',
                values: [request.params.id],
                name: 'orders_select_all_by_id'
            };

            request.pg.client.query(queryConfig, function (err, result) {

                if (err) {
                    return reply(err);
                }

                if (result.rows.length === 0) {
                    return reply(Boom.notFound(c.RecordNotFound));
                }

                var json = JSON.stringify(result.rows);

                reply(json);
            });
        }
    });


    // get all orders placed by the current user. auth.
    server.route({
        method: 'GET',
        path: options.basePath + '/orders/my',
        config: {
            auth: {
                strategy: 'token'
            }
        },
        handler: function (request, reply) {

            var uid = internals.getUserId(request);
            console.info('uid = %s', uid);
            var queryConfig = {
                text: 'SELECT id, uid, initial_price, final_price, currency, country, status, created_at, description, address, ST_X(venue) AS lon, ST_Y(venue) AS lat \
                       FROM orders \
                       WHERE uid = $1 \
                       ORDER BY id DESC',
                values: [uid],
                name: 'orders_select_my'
            };

            request.pg.client.query(queryConfig, function (err, result) {

                if (err) {
                    return reply(err);
                }

                if (result.rows.length === 0) {
                    return reply(Boom.notFound(c.RecordNotFound));
                }

                var json = JSON.stringify(result.rows);

                reply(json);
            });
        }
    });


    // get all orders won by the current user. auth.
    server.route({
        method: 'GET',
        path: options.basePath + '/orders/won',
        config: {
            auth: {
                strategy: 'simple'
            }
        },
        handler: function (request, reply) {

            var uid = internals.getUserId(request);
            var queryConfig = {
                text: 'SELECT id, uid, initial_price, final_price, currency, country, status, created_at, description, address, ST_X(venue) AS lon, ST_Y(venue) AS lat \
                       FROM orders \
                       WHERE winner_id = $1 \
                       ORDER BY id DESC',
                values: [uid],
                name: 'orders_select_won'
            };

            request.pg.client.query(queryConfig, function (err, result) {

                if (err) {
                    return reply(err);
                }

                if (result.rows.length === 0) {
                    return reply(Boom.notFound(c.RecordNotFound));
                }

                var json = JSON.stringify(result.rows);

                reply(json);
            });
        }
    });


    // get all orders nearby a venue. no auth.
    server.route({
        method: 'GET',
        path: options.basePath + '/orders/nearby',
        config: {
            validate: {
                query: {
                    lon: Joi.number().min(-180).max(180),
                    lat: Joi.number().min(-90).max(90),
                    distance: Joi.number().min(1).max(1000).default(80),
                    count: Joi.number().integer().min(1).max(200).default(50),
                    after: Joi.string().regex(/^[0-9]+$/).max(19).default('0'),
                    before: Joi.string().regex(/^[0-9]+$/).max(19).default('9223372036854775807')
                }
            }
        },
        handler: function (request, reply) {

            var queryConfig = {
                text: 'SELECT id, uid, initial_price, final_price, currency, country, status, created_at, description, address, ST_X(venue) AS lon, ST_Y(venue) AS lat \
                       FROM orders \
                       WHERE id > $1 AND id < $2 AND ST_DWithin(venue, ST_SetSRID(ST_MakePoint($3, $4), 4326), $5 / 111.325) \
                       ORDER BY id DESC \
                       LIMIT $6',
                values: [request.query.after, request.query.before, request.query.lon, request.query.lat, request.query.distance, request.query.count],
                name: 'orders_select_nearby'
            };

            request.pg.client.query(queryConfig, function (err, result) {

                if (err) {
                    return reply(err);
                }

                if (result.rows.length === 0) {
                    return reply(Boom.notFound(c.RecordNotFound));
                }

                var json = JSON.stringify(result.rows);

                reply(json);
            });
        }
    });


    // Create an order. auth.
    server.route({
        method: 'POST',
        path: options.basePath + '/order',
        config: {
            auth: {
                strategy: 'simple'
            },
            validate: {
                payload: {
                    price: Joi.number().precision(19),
                    currency: Joi.string().length(3).regex(/^[a-z]+$/),
                    country: Joi.string().length(2).regex(/^[a-z]+$/),
                    description: Joi.string().max(1000),
                    address: Joi.string(),
                    lon: Joi.number().min(-180).max(180),
                    lat: Joi.number().min(-90).max(90)
                }
            }
        },
        handler: internals.createOrderHandler
    });

    next();
};


exports.register.attributes = {
    name: 'orders'
};


internals.createOrderHandler = function (request, reply) {

    Async.waterfall([
        function (callback) {

            var uid = internals.getUserId(request);
            console.info('uid = %s', uid);
            var queryConfig = {
                text: 'INSERT INTO orders \
                           (uid, initial_price, currency, country, description, address, venue, created_at, updated_at) VALUES \
                           ($1, $2, $3, $4, $5, $6, ST_SetSRID(ST_MakePoint($7, $8), 4326), now(), now()) \
                           RETURNING id',
                values: [uid, request.payload.price, request.payload.currency, request.payload.country, request.payload.description, request.payload.address, request.payload.lon, request.payload.lat],
                name: 'orders_create'
            };

            request.pg.client.query(queryConfig, function (err, result) {

                if (err) {
                    callback(err);
                }
                else if (result.rows.length === 0) {
                    callback(Boom.badData(c.QueryFailed));
                }
                else {
                    callback(null, result.rows[0].id);
                }
            });
        }
    ], function (err, oid) {

        if (err) {
            return reply(err);
        }

        var json = JSON.stringify(oid);
        reply(json);
    });
};


// Get user id from the request
// At this step the authentication has succeeded, so the reqeust should contain valid credentials
internals.getUserId = function (request) {

    return request.auth.credentials.id;
};
