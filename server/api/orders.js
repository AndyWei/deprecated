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
                name: 'orders_select_all_by_id',
                text: 'SELECT id, uid, initial_price, final_price, currency, country, status, created_at, description, address, category, ST_X(venue) AS lon, ST_Y(venue) AS lat \
                       FROM orders \
                       WHERE id = $1  AND deleted = false',
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

            var userId = request.auth.credentials.id;
            var queryConfig = {
                name: 'orders_select_my',
                text: 'SELECT id, uid, initial_price, final_price, currency, country, status, category, created_at, description, address, ST_X(venue) AS lon, ST_Y(venue) AS lat \
                       FROM orders \
                       WHERE uid = $1 AND deleted = false \
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


    // get all orders won by the current user. auth.
    server.route({
        method: 'GET',
        path: options.basePath + '/orders/won',
        config: {
            auth: {
                strategy: 'token'
            }
        },
        handler: function (request, reply) {

            var userId = request.auth.credentials.id;
            var queryConfig = {
                name: 'orders_select_won',
                text: 'SELECT id, uid, initial_price, final_price, currency, country, status, category, created_at, description, address, ST_X(venue) AS lon, ST_Y(venue) AS lat \
                       FROM orders \
                       WHERE winner_id = $1 AND deleted = false \
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

            var q = request.query;
            var degree = internals.degreeFromDistance(q.distance);

            var queryConfig = {
                name: 'orders_select_nearby',
                text: 'SELECT id, uid, initial_price, final_price, currency, country, status, category, created_at, description, address, ST_X(venue) AS lon, ST_Y(venue) AS lat \
                       FROM orders \
                       WHERE id > $1 AND id < $2 AND ST_DWithin(venue, ST_SetSRID(ST_MakePoint($3, $4), 4326), $5) AND deleted = false \
                       ORDER BY id DESC \
                       LIMIT $6',
                values: [q.after, q.before, q.lon, q.lat, degree, q.count]
            };

            request.pg.client.query(queryConfig, function (err, result) {

                if (err) {
                    return reply(err);
                }

                reply(null, result.rows);
            });
        }
    });


    // get all orders in the categories nearby a venue. no auth.
    server.route({
        method: 'GET',
        path: options.basePath + '/orders/categorized/nearby',
        config: {
            validate: {
                query: {
                    lon: Joi.number().min(-180).max(180),
                    lat: Joi.number().min(-90).max(90),
                    distance: Joi.number().min(1).max(1000).default(80),
                    after: Joi.string().regex(/^[0-9]+$/).max(19).default('0'),
                    before: Joi.string().regex(/^[0-9]+$/).max(19).default('9223372036854775807'),
                    categories: Joi.array().single(true).unique().items(Joi.number().min(0).max(100))
                }
            }
        },
        handler: function (request, reply) {

            var q = request.query;
            var degree = internals.degreeFromDistance(q.distance);

            var queryConfig = {
                // Warning: Do not give this query a name!! Because it has variable number of parameters and cannot be a prepared statement.
                // See https://github.com/brianc/node-postgres/wiki/Client#method-query-prepared
                text: internals.createCategoryQueryText(q.categories),
                values: [q.after, q.before, q.lon, q.lat, degree].concat(q.categories)
            };

            request.pg.client.query(queryConfig, function (err, result) {

                if (err) {
                    return reply(err);
                }

                reply(null, result.rows);
            });
        }
    });


    // Create an order. auth.
    server.route({
        method: 'POST',
        path: options.basePath + '/order',
        config: {
            auth: {
                strategy: 'token'
            },
            validate: {
                payload: {
                    lon: Joi.number().min(-180).max(180),
                    lat: Joi.number().min(-90).max(90),
                    price: Joi.number().precision(19),
                    currency: Joi.string().length(3).regex(/^[a-z]+$/),
                    country: Joi.string().length(2).regex(/^[a-z]+$/),
                    category: Joi.number().min(0).max(100),
                    description: Joi.string().max(1000),
                    address: Joi.string()
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

            var userId = request.auth.credentials.id;
            var p = request.payload;
            var queryConfig = {
                name: 'orders_create',
                text: 'INSERT INTO orders \
                           (uid, initial_price, currency, country, category, description, address, venue, created_at, updated_at) VALUES \
                           ($1, $2, $3, $4, $5, $6, $7, ST_SetSRID(ST_MakePoint($8, $9), 4326), now(), now()) \
                           RETURNING id',
                values: [userId, p.price, p.currency, p.country, p.category, p.description, p.address, p.lon, p.lat]
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
    ], function (err, order) {

        if (err) {
            return reply(err);
        }

        reply(null, order);
    });
};


internals.createCategoryQueryText = function (categories) {

    var select = 'SELECT id, uid, initial_price, final_price, currency, country, status, category, created_at, description, address, ST_X(venue) AS lon, ST_Y(venue) AS lat ';
    var from = 'FROM orders ';
    var where1 = 'WHERE id > $1 AND id < $2 AND ST_DWithin(venue, ST_SetSRID(ST_MakePoint($3, $4), 4326), $5) AND deleted = false ';
    var order = 'ORDER BY id DESC ';
    var limit = 'LIMIT 50';

    var where2 = 'AND category IN ($6';
    for (var i = 0, il = categories.length - 1; i < il; ++i) {
        where2 += ', $' + (i + 7).toString();
    }
    where2 += ') ';

    return select + from + where1 + where2 + order + limit;
};


// convert distance in km to GPS degree
internals.degreeFromDistance = function(distance) {

    return distance * c.DEGREE_FACTOR;
};

