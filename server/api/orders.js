var Async = require('async');
var Boom = require('boom');
var Hoek = require('hoek');
var Joi = require('joi');
var c = require('../constants');

var internals = {};
var selectClause = 'SELECT id, user_id, price, currency, country, status, category, title, note, startTime, startCity, startAddress, endAddress, winner_id, final_price, created_at, updated_at, \
                    ST_X(startPoint) AS startPointLon, ST_Y(startPoint) AS startPointLat, ST_X(endPoint) AS endPointLon, ST_Y(endPoint) AS endPointLat \
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


    // get all unpaid orders placed by the current user. auth.
    server.route({
        method: 'GET',
        path: options.basePath + '/orders/unpaid',
        config: {
            auth: {
                strategy: 'token'
            },
            validate: {
                query: {
                    after: Joi.string().regex(/^[0-9]+$/).max(19).default('0')
                }
            }
        },
        handler: function (request, reply) {

            var userId = request.auth.credentials.id;
            var queryConfig = {
                name: 'orders_unpaid',
                text: selectClause +
                      'WHERE id > $1 AND user_id = $2 AND status < 10 AND deleted = false \
                       ORDER BY id DESC',
                values: [request.query.after, userId]
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


    // get all paid orders placed by the current user. auth.
    server.route({
        method: 'GET',
        path: options.basePath + '/orders/paid',
        config: {
            auth: {
                strategy: 'token'
            }
        },
        handler: function (request, reply) {

            var userId = request.auth.credentials.id;
            var queryConfig = {
                name: 'orders_paid',
                text: selectClause +
                      'WHERE user_id = $1 AND status = 10 AND deleted = false \
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
                name: 'orders_won',
                text: selectClause +
                      'WHERE winner_id IS NOT NULL AND winner_id = $1 AND deleted = false \
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
                    category: Joi.array().sparse(true).single(true).unique().items(Joi.number().min(0).max(100))
                }
            }
        },
        handler: function (request, reply) {

            var queryConfig = internals.createNearbyQueryConfig(request.query);
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
                    category: Joi.number().min(0).max(100),
                    country: Joi.string().length(2).regex(/^[a-z]+$/),
                    currency: Joi.string().length(3).regex(/^[a-z]+$/),
                    title: Joi.string().max(100),
                    note: Joi.string().max(1000),
                    price: Joi.number().precision(2).min(0).max(100000000),
                    startTime: Joi.number().min(450600000),
                    startPointLon: Joi.number().min(-180).max(180),
                    startPointLat: Joi.number().min(-90).max(90),
                    startCity: Joi.string().max(30),
                    startAddress: Joi.string().max(200),
                    endPointLon: Joi.number().min(-180).max(180).optional(),
                    endPointLat: Joi.number().min(-90).max(90).optional(),
                    endAddress: Joi.string().optional()
                }
            }
        },
        handler: function (request, reply) {

            Async.waterfall([
                function (callback) {

                    internals.createInsertQueryConfig(request, function (err, queryConfig) {
                        if (err) {
                            request.pg.kill = true;
                            return callback(err);
                        }

                        callback(null, queryConfig);
                    });
                },
                function (queryConfig, callback) {

                    request.pg.client.query(queryConfig, function (err, result) {

                        if (err) {
                            request.pg.kill = true;
                            return callback(err);
                        }
                        if (result.rows.length === 0) {
                            return reply(Boom.badRequest(c.ORDER_CREATE_FAILED));
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
                text: 'UPDATE orders SET status = 20, updated_at = now() ' +
                      'WHERE id = $1 AND user_id = $2 AND status = 0 AND deleted = false ' +
                      'RETURNING id, status',
                values: [request.params.order_id, request.auth.credentials.id]
            };

            request.pg.client.query(queryConfig, function (err, result) {

                if (err) {
                    console.error(err);
                    request.pg.kill = true;
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
                    startAddress: Joi.string().max(100).optional(),
                    category: Joi.number().min(0).max(100).optional(),
                    note: Joi.string().max(1000).optional(),
                    startPointLat: Joi.number().min(-90).max(90).optional(),
                    startPointLon: Joi.number().min(-180).max(180).optional(),
                    price: Joi.number().precision(2).min(0).max(100000000).optional()
                }
            }
        },
        handler: function (request, reply) {

            Async.waterfall([
                function (callback) {

                    internals.createUpdateQueryConfig(request, function (err, queryConfig) {
                        if (err) {
                            request.pg.kill = true;
                            return callback(err);
                        }

                        callback(null, queryConfig);
                    });
                },
                function (queryConfig, callback) {

                    request.pg.client.query(queryConfig, function (err, result) {

                        if (err) {
                            request.pg.kill = true;
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


internals.createInsertQueryConfig = function (request, callback) {

    var userId = request.auth.credentials.id;
    var p = request.payload;

    var queryText1 = 'INSERT INTO orders (user_id, price, currency, country, category, title, note, startTime, startCity, startAddress, startPoint, created_at, updated_at';
    var queryText2 = '($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, ST_SetSRID(ST_MakePoint($11, $12), 4326), now(), now()';
    var queryValues = [userId, p.price, p.currency, p.country, p.category, p.title, p.note, p.startTime, p.startCity, p.startAddress, p.startPointLon, p.startPointLat];

    if (p.endPointLon && p.endPointLat && p.endAddress) {
        queryText1 += ', endAddress, endPoint) VALUES ';
        queryText2 += ', $13, ST_SetSRID(ST_MakePoint($14, $15), 4326)) RETURNING id';

        queryValues.push(p.endAddress);
        queryValues.push(p.endPointLon);
        queryValues.push(p.endPointLat);
    }
    else if (p.endPointLon || p.endPointLat || p.endAddress) {
        return callback(Boom.badData(c.COORDINATE_INVALID));
    }
    else {
        queryText1 += ') VALUES ';
        queryText2 += ') RETURNING id';
    }

    var queryConfig = {
        // Warning: Do not give this query a name!! Because it has variable number of parameters and cannot be a prepared statement.
        // See https://github.com/brianc/node-postgres/wiki/Client#method-query-prepared
        text: queryText1 + queryText2,
        values: queryValues
    };

    callback(null, queryConfig);
};


internals.createUpdateQueryConfig = function (request, callback) {

    var orderId = request.params.order_id;
    var userId = request.auth.credentials.id;
    var p = request.payload;

    var queryText = 'UPDATE orders SET ';
    var queryValues = [];
    var index = 1;

    if (p.startPointLon && p.startPointLat) {
        queryText += 'startPoint = ST_SetSRID(ST_MakePoint($1, $2), 4326),';
        queryValues.push(p.startPointLon);
        queryValues.push(p.startPointLat);
        index += 2;
    }
    else if (p.startPointLon || p.startPointLat) {
        return callback(Boom.badData(c.COORDINATE_INVALID));
    }

    if (p.startAddress) {
        queryText += 'startAddress = $' + index.toString() + ',';
        queryValues.push(p.startAddress);
        ++index;
    }

    if (p.category) {
        queryText += 'category = $' + index.toString() + ',';
        queryValues.push(p.category);
        ++index;
    }

    if (p.note) {
        queryText += 'note = $' + index.toString() + ',';
        queryValues.push(p.note);
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
    queryText += 'RETURNING id, price, status, category, note, startAddress, created_at, updated_at, \
                  ST_X(startPoint) AS startPointLon, ST_Y(startPoint) AS startPointLat, ST_X(endPoint) AS endPointLon, ST_Y(endPoint) AS endPointLat';

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

    var where1 = 'WHERE id > $1 AND id < $2 AND ST_DWithin(startPoint, ST_SetSRID(ST_MakePoint($3, $4), 4326), $5) AND status = 0 AND deleted = false ';
    var order = 'ORDER BY id DESC ';
    var limit = 'LIMIT 50';

    var queryValues = [query.after, query.before, query.lon, query.lat, degree];
    var where2 = '';
    if (query.category) {

        where2 += 'AND category IN ($6';
        for (var i = 0, il = query.category.length - 1; i < il; ++i) {
            where2 += ', $' + (i + 7).toString();
        }
        where2 += ') ';

        queryValues = queryValues.concat(query.category);
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
