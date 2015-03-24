var Async = require('async');
var Boom = require('boom');
var Hoek = require('hoek');
var Joi = require('joi');
var c = require('../constants');

var internals = {};
var selectClause = 'SELECT id, user_id, price, currency, country, status, category, description, address, winner_id, final_price, created_at, updated_at, ST_X(venue) AS lon, ST_Y(venue) AS lat \
                    FROM orders ';

exports.register = function (server, options, next) {

    options = Hoek.applyToDefaults({ basePath: '' }, options);

    // get a single order by id. no auth.
    server.route({
        method: 'GET',
        path: options.basePath + '/orders/{id}',
        config: {
            validate: {
                params: {
                    id: Joi.string().regex(/^[0-9]+$/).max(19)
                }
            }
        },
        handler: function (request, reply) {

            var queryConfig = {
                name: 'orders_by_id',
                text: selectClause +
                      'WHERE id = $1 AND deleted = false',
                values: [request.params.id]
            };

            request.pg.client.query(queryConfig, function (err, result) {

                if (err) {
                    console.error(err);
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
        path: options.basePath + '/orders/from_me',
        config: {
            auth: {
                strategy: 'token'
            }
        },
        handler: function (request, reply) {

            var userId = request.auth.credentials.id;
            var queryConfig = {
                name: 'orders_from_me',
                text: selectClause +
                      'WHERE user_id = $1 AND deleted = false \
                       ORDER BY id DESC',
                values: [userId]
            };

            request.pg.client.query(queryConfig, function (err, result) {

                if (err) {
                    console.error(err);
                    return reply(err);
                }

                reply(null, result.rows);
            });
        }
    });


    // get all orders won by the current user. auth.
    server.route({
        method: 'GET',
        path: options.basePath + '/orders/won_by_me',
        config: {
            auth: {
                strategy: 'token'
            }
        },
        handler: function (request, reply) {

            var userId = request.auth.credentials.id;
            var queryConfig = {
                name: 'orders_won_by_me',
                text: selectClause +
                      'WHERE winner_id IS NOT NULL AND winner_id = $1 AND deleted = false \
                       ORDER BY id DESC',
                values: [userId]
            };

            request.pg.client.query(queryConfig, function (err, result) {

                if (err) {
                    console.error(err);
                    return reply(err);
                }

                reply(null, result.rows);
            });
        }
    });


    // get all the orders nearby a venue. no auth.
    server.route({
        method: 'GET',
        path: options.basePath + '/orders/nearby',
        config: {
            validate: {
                query: {
                    lon: Joi.number().min(-180).max(180),
                    lat: Joi.number().min(-90).max(90),
                    distance: Joi.number().min(1).max(1000).default(80),
                    after: Joi.string().regex(/^[0-9]+$/).max(19).default('0'),
                    before: Joi.string().regex(/^[0-9]+$/).max(19).default('9223372036854775807'),
                    categories: Joi.array().sparse(true).single(true).unique().items(Joi.number().min(0).max(100))
                }
            }
        },
        handler: function (request, reply) {

            var queryConfig = internals.createNearbyQueryConfig(request.query);
            request.pg.client.query(queryConfig, function (err, result) {

                if (err) {
                    console.error(err);
                    return reply(err);
                }

                reply(null, result.rows);
            });
        }
    });


    // create an order. auth.
    server.route({
        method: 'POST',
        path: options.basePath + '/orders',
        config: {
            auth: {
                strategy: 'token'
            },
            validate: {
                payload: {
                    address: Joi.string(),
                    category: Joi.number().min(0).max(100),
                    currency: Joi.string().length(3).regex(/^[a-z]+$/),
                    country: Joi.string().length(2).regex(/^[a-z]+$/),
                    description: Joi.string().max(1000),
                    lon: Joi.number().min(-180).max(180),
                    lat: Joi.number().min(-90).max(90),
                    price: Joi.number().precision(2).min(0).max(100000000)
                }
            }
        },
        handler: internals.createOrderHandler
    });


    // revoke an order. auth.
    server.route({
        method: 'POST',
        path: options.basePath + '/orders/revoke/{order_id}',
        config: {
            auth: {
                strategy: 'token'
            },
            validate: {
                params: {
                    order_id: Joi.string().regex(/^[0-9]+$/).max(19)
                }
            }
        },
        handler: function (request, reply) {

            var queryConfig = {
                name: 'orders_revoke',
                text: 'UPDATE orders SET status = 1, updated_at = now() ' +
                      'WHERE id = $1 AND user_id = $2 AND status = 0 AND deleted = false ' +
                      'RETURNING id, status',
                values: [request.params.order_id, request.auth.credentials.id]
            };

            request.pg.client.query(queryConfig, function (err, result) {

                if (err) {
                    return reply(err);
                }

                if (result.rows.length === 0) {
                    return reply(Boom.badRequest(c.ORDER_REVOKE_FAILED));
                }

                reply(null, result.rows[0]);
            });
        }
    });


    // update an order. auth.
    server.route({
        method: 'POST',
        path: options.basePath + '/orders/{order_id}',
        config: {
            auth: {
                strategy: 'token'
            },
            validate: {
                params: {
                    order_id: Joi.string().regex(/^[0-9]+$/).max(19)
                },
                payload: {
                    address: Joi.string().max(100).optional(),
                    category: Joi.number().min(0).max(100).optional(),
                    description: Joi.string().max(1000).optional(),
                    lat: Joi.number().min(-90).max(90).optional(),
                    lon: Joi.number().min(-180).max(180).optional(),
                    price: Joi.number().precision(2).min(0).max(100000000).optional()
                }
            }
        },
        handler: function (request, reply) {

            Async.waterfall([
                function (callback) {

                    internals.createUpdateQueryConfig(request, function (err, queryConfig) {
                        if (err) {
                            return callback(err);
                        }

                        callback(null, queryConfig);
                    });
                },
                function (queryConfig, callback) {

                    request.pg.client.query(queryConfig, function (err, result) {

                        if (err) {
                            return callback(err);
                        }
                        if (result.rows.length === 0) {
                            return reply(Boom.badRequest(c.ORDER_UPDATE_FAILED));
                        }

                        callback(null, result.rows[0]);
                    });
                }
            ], function (err, order) {

                if (err) {
                    console.error(err);
                    return reply(err);
                }

                reply(null, order);
            });
        }
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
                           (user_id, price, currency, country, category, description, address, venue, created_at, updated_at) VALUES \
                           ($1, $2, $3, $4, $5, $6, $7, ST_SetSRID(ST_MakePoint($8, $9), 4326), now(), now()) \
                           RETURNING id',
                values: [userId, p.price, p.currency, p.country, p.category, p.description, p.address, p.lon, p.lat]
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
    ], function (err, order) {

        if (err) {
            console.error(err);
            return reply(err);
        }

        reply(null, order);
    });
};


internals.createUpdateQueryConfig = function (request, callback) {

    var orderId = request.params.order_id;
    var userId = request.auth.credentials.id;
    var p = request.payload;

    var queryText = 'UPDATE orders SET ';
    var queryValues = [];
    var index = 1;

    if (p.lon && p.lat) {
        queryText += 'venue = ST_SetSRID(ST_MakePoint($1, $2), 4326),';
        queryValues.push(p.lon);
        queryValues.push(p.lat);
        index += 2;
    }
    else if (p.lon || p.lat) {
        return callback(Boom.badData(c.COORDINATE_INVALID));
    }

    if (p.address) {
        queryText += 'address = $' + index.toString() + ',';
        queryValues.push(p.address);
        ++index;
    }

    if (p.category) {
        queryText += 'category = $' + index.toString() + ',';
        queryValues.push(p.category);
        ++index;
    }

    if (p.description) {
        queryText += 'description = $' + index.toString() + ',';
        queryValues.push(p.description);
        ++index;
    }

    if (p.price) {
        queryText += 'price = $' + index.toString() + ',';
        queryValues.push(p.price);
        ++index;
    }

    if (index === 1) {
        return callback(Boom.badData(c.QUERY_INVALID));
    }

    queryText += 'updated_at = now() ';
    queryText += 'WHERE id = $' + index.toString() + ' AND user_id = $' + (index + 1).toString() + ' AND status = 0 AND deleted = false ';
    queryText += 'RETURNING id, price, status, category, description, address, created_at, updated_at, ST_X(venue) AS lon, ST_Y(venue) AS lat';

    queryValues.push(orderId);
    queryValues.push(userId);

    var queryConfig = {
        // Warning: Do not give this query a name!! Because it has variable number of parameters and cannot be a prepared statement.
        // See https://github.com/brianc/node-postgres/wiki/Client#method-query-prepared
        text: queryText,
        values: queryValues
    };

    callback(null, queryConfig);
};


internals.createNearbyQueryConfig = function (query) {

    var degree = internals.degreeFromDistance(query.distance);

    var where1 = 'WHERE id > $1 AND id < $2 AND ST_DWithin(venue, ST_SetSRID(ST_MakePoint($3, $4), 4326), $5) AND status = 0 AND deleted = false ';
    var order = 'ORDER BY id DESC ';
    var limit = 'LIMIT 50';

    var queryValues = [query.after, query.before, query.lon, query.lat, degree];
    var where2 = '';
    if (query.categories) {

        where2 += 'AND category IN ($6';
        for (var i = 0, il = query.categories.length - 1; i < il; ++i) {
            where2 += ', $' + (i + 7).toString();
        }
        where2 += ') ';

        queryValues = queryValues.concat(query.categories);
    }

    var queryConfig = {
        // Warning: Do not give this query a name!! Because it has variable number of parameters and cannot be a prepared statement.
        // See https://github.com/brianc/node-postgres/wiki/Client#method-query-prepared
        text: selectClause + where1 + where2 + order + limit,
        values: queryValues
    };

    return queryConfig;
};


// convert distance in km to GPS degree
internals.degreeFromDistance = function(distance) {

    return distance * c.DEGREE_FACTOR;
};
