var Async = require('async');
var Boom = require('boom');
var Config = require('../../config');
var Hoek = require('hoek');
var Joi = require('joi');
var Push = require('../push');
var Stripe = require('stripe')(Config.get('/stripe/platformSecretKey'));
var Utils = require('../utils');
var c = require('../constants');
var _ = require('underscore');


var internals = {};
var selectClause = 'SELECT id, user_id, price, currency, country, status, category, title, note, start_time, start_city, start_address, end_address, \
                    winner_id, winner_name, final_price, created_at, updated_at, finished_at, \
                    ST_X(start_point) AS start_point_lon, ST_Y(start_point) AS start_point_lat, ST_X(end_point) AS end_point_lon, ST_Y(end_point) AS end_point_lat \
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


    // get all orders with specified status placed by the current user. auth.
    server.route({
        method: 'GET',
        path: options.basePath + '/orders/my',
        config: {
            auth: {
                strategy: 'token'
            },
            validate: {
                query: {
                    status: Joi.number().min(0).max(100).default(0),
                    after: Joi.string().regex(/^[0-9]+$/).max(19).default('0'),
                    before: Joi.string().regex(/^[0-9]+$/).max(19).default('9223372036854775807')
                }
            }
        },
        handler: function (request, reply) {

            var userId = request.auth.credentials.id;
            var q = request.query;
            var queryConfig = {
                name: 'orders_my',
                text: selectClause +
                      'WHERE user_id = $1 AND status = $2 AND id > $3 AND id < $4 AND deleted = false \
                       ORDER BY id DESC LIMIT 100',
                values: [userId, q.status, q.after, q.before]
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
                       ORDER BY id DESC LIMIT 200',
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


    // get all the orders nearby a point. no auth.
    server.route({
        method: 'GET',
        path: options.basePath + '/orders/nearby',
        config: {
            validate: {
                query: {
                    lon: Joi.number().min(-180).max(180).required(),
                    lat: Joi.number().min(-90).max(90).required(),
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


    // get all the active orders the user engaged (bidded or commented). auth.
    server.route({
        method: 'GET',
        path: options.basePath + '/orders/engaged',
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

            Async.waterfall([
                function (callback) {

                    internals.getEngagedOrderIds(request, function (err, orderIds) {

                        if (err) {
                            return callback(err);
                        }

                        if (!orderIds || orderIds.length === 0) {
                            return callback('empty');
                        }

                        callback(null, orderIds);
                    });
                },
                function (orderIds, callback) {

                    var where = 'WHERE status = 0 AND deleted = false AND id IN ' + Utils.parametersString(1, orderIds.length);
                    var sort = 'ORDER BY id DESC LIMIT 100';

                    var queryConfig = {
                        // Warning: Do not give this query a name!! Because it has variable number of parameters and cannot be a prepared statement.
                        // See https://github.com/brianc/node-postgres/wiki/Client#method-query-prepared
                        text: selectClause + where + sort,
                        values: orderIds
                    };

                    request.pg.client.query(queryConfig, function (err, result) {

                        if (err) {
                            request.pg.kill = true;
                            return callback(err);
                        }
                        if (result.rows.length === 0) {
                            return reply(Boom.badRequest(c.RECORD_NOT_FOUND));
                        }

                        callback(null, result.rows);
                    });
                }
            ], function (err, orders) {

                if (err === 'empty') {
                    return reply(null, []);
                }

                if (err) {
                    console.error(err);
                    return reply(err);
                }

                reply(null, orders);
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
                    category: Joi.number().min(0).max(100).required(),
                    country: Joi.string().length(2).regex(/^[a-z]+$/).required(),
                    currency: Joi.string().length(3).regex(/^[a-z]+$/).required(),
                    title: Joi.string().max(100).required(),
                    note: Joi.string().max(1000).required(),
                    price: Joi.number().min(0).max(10000000000).required(),
                    start_time: Joi.number().min(450600000).required(),
                    start_point_lon: Joi.number().min(-180).max(180).required(),
                    start_point_lat: Joi.number().min(-90).max(90).required(),
                    start_city: Joi.string().max(30).required(),
                    start_address: Joi.string().max(200).required(),
                    end_point_lon: Joi.number().min(-180).max(180).optional(),
                    end_point_lat: Joi.number().min(-90).max(90).optional(),
                    end_address: Joi.string().optional()
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
                    start_address: Joi.string().max(100).optional(),
                    category: Joi.number().min(0).max(100).optional(),
                    note: Joi.string().max(1000).optional(),
                    start_point_lat: Joi.number().min(-90).max(90).optional(),
                    start_point_lon: Joi.number().min(-180).max(180).optional(),
                    price: Joi.number().min(0).max(10000000000).optional()
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


    // update an order's working status to ongoing. auth. This can only be done by the order winner.
    server.route({
        method: 'POST',
        path: options.basePath + '/orders/started',
        config: {
            auth: {
                strategy: 'token'
            },
            validate: {
                payload: {
                    order_id: Joi.string().regex(/^[0-9]+$/).max(19).required()
                }
            }
        },
        handler: function (request, reply) {

            var p = request.payload;
            var u = request.auth.credentials;

            var queryConfig = {
                name: 'orders_started',
                text: 'UPDATE orders SET status = 2, updated_at = now() ' +
                      'WHERE id = $1 AND winner_id = $2 AND status = 1 AND deleted = false ' +
                      'RETURNING id, user_id, status',
                values: [p.order_id, u.id]
            };

            request.pg.client.query(queryConfig, function (err, result) {

                if (err) {
                    console.error(err);
                    request.pg.kill = true;
                    return reply(err);
                }

                if (result.rows.length === 0) {
                    return reply(Boom.badRequest(c.ORDER_UPDATE_WORKING_STATUS_FAILED));
                }

                // send notification to the order owner
                var title = '@' + u.username + ' will start service';
                Push.notify('joyy', result.rows[0].user_id, title, 'start_service', function (error) {

                    if (error) {
                        console.error(error);
                    }
                });
                reply(null, result.rows[0]);
            });
        }
    });


    // update an order's working status to finished. auth. This can only be done by the order winner.
    server.route({
        method: 'POST',
        path: options.basePath + '/orders/finished',
        config: {
            auth: {
                strategy: 'token'
            },
            validate: {
                payload: {
                    order_id: Joi.string().regex(/^[0-9]+$/).max(19).required()
                }
            }
        },
        handler: function (request, reply) {

            var p = request.payload;
            var u = request.auth.credentials;

            var queryConfig = {
                name: 'orders_finished',
                text: 'UPDATE orders SET status = 3, finished_at = now(), updated_at = now() ' +
                      'WHERE id = $1 AND winner_id = $2 AND status = 2 AND deleted = false ' +
                      'RETURNING id, user_id, status',
                values: [p.order_id, u.id]
            };

            request.pg.client.query(queryConfig, function (err, result) {

                if (err) {
                    console.error(err);
                    request.pg.kill = true;
                    return reply(err);
                }

                if (result.rows.length === 0) {
                    return reply(Boom.badRequest(c.ORDER_UPDATE_WORKING_STATUS_FAILED));
                }

                // send notification to the order owner
                var title = 'Please confirm @' + u.username + ' has finished the service';
                Push.notify('joyy', result.rows[0].user_id, title, 'finish_service', function (error) {

                    if (error) {
                        console.error(error);
                    }
                });
                reply(null, result.rows[0]);
            });
        }
    });


    // confirm an order has been finished and pay the the order winner. auth. This can only be done by the order owner.
    server.route({
        method: 'POST',
        path: options.basePath + '/orders/paid',
        config: {
            auth: {
                strategy: 'token'
            },
            validate: {
                payload: {
                    order_id: Joi.string().regex(/^[0-9]+$/).max(19).required()
                }
            }
        },
        handler: internals.createPaymentHandler
    });

    next();
};


exports.register.attributes = {
    name: 'orders'
};


internals.getEngagedOrderIds = function (request, callback) {

    var userId = request.auth.credentials.id;
    var minOrderId = request.query.after;

    // read from redis cache first, if cache miss, then read from DB
    Async.auto({
        bidded: function (next) {

            var queryConfig = {
                name: 'order_id_bidded',
                text: 'SELECT order_id FROM bids WHERE user_id = $1 AND order_id > $2 AND status = 0 AND deleted = false \
                       ORDER BY id DESC LIMIT 100',
                values: [userId, minOrderId]
            };

            request.pg.client.query(queryConfig, function (err, result) {

                if (err) {
                    request.pg.kill = true;
                    return next(err);
                }

                next(null, _.pluck(result.rows, 'order_id'));
            });
        },
        commented: function (next) {

            var queryConfig = {
                name: 'order_id_commented',
                text: 'SELECT order_id FROM comments WHERE user_id = $1 AND order_id > $2 AND deleted = false \
                       ORDER BY id DESC LIMIT 100',
                values: [userId, minOrderId]
            };

            request.pg.client.query(queryConfig, function (err, result) {

                if (err) {
                    request.pg.kill = true;
                    return next(err);
                }

                next(null, _.pluck(result.rows, 'order_id'));
            });
        }
    }, function (err, results) {

        if (err) {
            console.error(err);
            return callback(err);
        }

        var orderIds = _.union(results.bidded, results.commented);
        callback(null, orderIds);
    });
};


internals.createInsertQueryConfig = function (request, callback) {

    var userId = request.auth.credentials.id;
    var p = request.payload;

    var queryText1 = 'INSERT INTO orders (user_id, price, currency, country, category, title, note, start_time, start_city, start_address, start_point, created_at, updated_at';
    var queryText2 = '($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, ST_SetSRID(ST_MakePoint($11, $12), 4326), now(), now()';
    var queryValues = [userId, p.price, p.currency, p.country, p.category, p.title, p.note, p.start_time, p.start_city, p.start_address, p.start_point_lon, p.start_point_lat];

    if (p.end_point_lon && p.end_point_lat && p.end_address) {
        queryText1 += ', end_address, end_point) VALUES ';
        queryText2 += ', $13, ST_SetSRID(ST_MakePoint($14, $15), 4326)) RETURNING id';

        queryValues.push(p.end_address);
        queryValues.push(p.end_point_lon);
        queryValues.push(p.end_point_lat);
    }
    else if (p.end_point_lon || p.end_point_lat || p.end_address) {
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

    if (p.start_point_lon && p.start_point_lat) {
        queryText += 'start_point = ST_SetSRID(ST_MakePoint($1, $2), 4326),';
        queryValues.push(p.start_point_lon);
        queryValues.push(p.start_point_lat);
        index += 2;
    }
    else if (p.start_point_lon || p.start_point_lat) {
        return callback(Boom.badData(c.COORDINATE_INVALID));
    }

    if (p.start_address) {
        queryText += 'start_address = $' + index.toString() + ',';
        queryValues.push(p.start_address);
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
    queryText += 'RETURNING id, price, status, category, note, start_address, created_at, updated_at, \
                  ST_X(start_point) AS start_point_lon, ST_Y(start_point) AS start_point_lat, ST_X(end_point) AS end_point_lon, ST_Y(end_point) AS end_point_lat';

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

    var where1 = 'WHERE id > $1 AND id < $2 AND ST_DWithin(start_point, ST_SetSRID(ST_MakePoint($3, $4), 4326), $5) AND status = 0 AND deleted = false ';
    var order = 'ORDER BY id DESC ';
    var limit = 'LIMIT 100';

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


internals.createPaymentHandler = function (request, reply) {

    var u = request.auth.credentials;
    var p = request.payload;

    Async.auto({
        order: function (next) {

            var queryConfig = {
                name: 'orders_finished_by_id',
                text: 'SELECT title, stripe_token, winner_id, final_price FROM orders ' +
                      'WHERE id = $1 AND user_id = $2 AND status = 3 AND deleted = false ',
                values: [p.order_id, u.id]
            };

            request.pg.client.query(queryConfig, function (err, result) {

                if (err) {
                    console.error(err);
                    request.pg.kill = true;
                    return next(err);
                }

                if (result.rows.length === 0) {
                    return next(Boom.badRequest(c.ORDER_STRIPE_TOKEN_NOT_FOUND));
                }

                next(null, result.rows[0]);
            });
        },
        account: ['order', function (next, results) {

            var winnerId = results.order.winner_id;
            var queryConfig = {
                name: 'accounts_id_by_user_id',
                text: 'SELECT stripe_account_id FROM accounts ' +
                      'WHERE user_id = $1 AND deleted = false ',
                values: [winnerId]
            };

            request.pg.client.query(queryConfig, function (err, result) {

                if (err) {
                    console.error(err);
                    request.pg.kill = true;
                    return next(err);
                }

                if (result.rows.length === 0) {
                    return next(Boom.badRequest(c.ACCOUNT_NOT_FOUND));
                }

                next(null, result.rows[0].stripe_account_id);
            });
        }],
        stripe: ['account', function (next, results) {

            var amount = results.order.final_price;             // both amount and final_price are in cents
            var joyyFee = amount * 0.05;                        // fee is 5%, in cents.
            var stripeFee = Math.floor(amount * 0.029) + 30;    // strie will take 30 cents plus 2.9% of amount
            var applicationFee = Math.max(joyyFee, stripeFee);  // application fee should at least cover joyy fee

            var description = 'Pay Joyy ' + results.order.title;
            var tokenPrefix = results.order.stripe_token.substring(0, 4);
            var shouldChargeOnCustomerId = (tokenPrefix === 'cus_');

            var chargeParameters = {
                amount: amount,
                currency: 'usd',
                destination: results.account,
                application_fee: applicationFee,
                description: description
            };

            if (shouldChargeOnCustomerId) {
                chargeParameters.customer = results.order.stripe_token;
            }
            else {
                chargeParameters.source = results.order.stripe_token;
            }

            Stripe.charges.create(chargeParameters, function (err, charge) {

                if (err) {
                    return next(err);
                }

                console.log(charge);

                next(null, charge);
            });
        }],
        orderStatus: ['stripe', function (next, results) {

            var queryConfig = {
                name: 'orders_paid',
                text: 'UPDATE orders SET status = 10, stripe_charge_id = $1, updated_at = now() ' +
                      'WHERE id = $2 AND user_id = $3 AND status = 3 AND deleted = false ' +
                      'RETURNING id, status',
                values: [results.stripe.id, p.order_id, u.id]
            };

            request.pg.client.query(queryConfig, function (err, result) {

                if (err) {
                    console.error(err);
                    request.pg.kill = true;
                    return next(err);
                }

                if (result.rows.length === 0) {
                    return next(Boom.badRequest(c.ORDER_UPDATE_WORKING_STATUS_FAILED));
                }

                next(null, result.rows[0]);
            });
        }]
    }, function (err, results) {

        if (err) {
            console.error(err);
            return reply(err);
        }

        // send notification to the order winner
        var amount = Utils.formatMoney(results.order.final_price);
        var title = 'Received payment $' + amount + 'from @' + u.username;
        Push.notify('joyyor', results.order.winner_id, title, title, function (error) {

            if (error) {
                console.error(error);
            }
        });
        reply(null, results.orderStatus);
    });
};


// convert distance in km to GPS degree
internals.degreeFromDistance = function(distance) {

    return distance * c.DEGREE_FACTOR;
};
