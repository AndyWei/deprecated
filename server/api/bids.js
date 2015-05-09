var Async = require('async');
var Boom = require('boom');
var Hoek = require('hoek');
var Joi = require('joi');
var Push = require('../push');
var c = require('../constants');

var internals = {};

exports.register = function (server, options, next) {

    options = Hoek.applyToDefaults({ basePath: '' }, options);

    // get a single bid by id. no auth.
    server.route({
        method: 'GET',
        path: options.basePath + '/bids/{bid_id}',
        config: {
            validate: {
                params: {
                    bid_id: Joi.string().regex(/^[0-9]+$/).max(19)
                }
            }
        },
        handler: function (request, reply) {

            var queryConfig = {
                name: 'bids_by_id',
                text: 'SELECT * FROM bids WHERE id = $1 AND deleted = false',
                values: [request.params.bid_id]
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


    // get the bids against the orders. auth.
    server.route({
        method: 'GET',
        path: options.basePath + '/bids/of/orders',
        config: {
            auth: {
                strategy: 'token'
            },
            validate: {
                query: {
                    after: Joi.string().regex(/^[0-9]+$/).max(19).default('0'),
                    order_id: Joi.array().single(true).unique().items(Joi.string().regex(/^[0-9]+$/).max(19))
                }
            }
        },
        handler: function (request, reply) {

            var queryValues = [request.query.after];
            var select = 'SELECT b.id, b.order_id, b.bidder_id, b.price, b.status, b.expire_at, u.username, u.rating_total, u.rating_count, u.bio FROM bids AS b ';
            var join = 'INNER JOIN users AS u ON u.id = b.bidder_id ';
            var where1 = 'WHERE b.id > $1 AND b.status < 10 AND b.deleted = false AND u.deleted = false ';
            var sort = 'ORDER BY b.id DESC';

            var where2 = 'AND b.order_id IN ($2';
            for (var i = 0, il = request.query.order_id.length - 1; i < il; ++i) {
                where2 += ', $' + (i + 3).toString();
            }
            where2 += ') ';

            queryValues = queryValues.concat(request.query.order_id);

            var queryConfig = {
                name: 'bids_for_me',
                text: select + join + where1 + where2 + sort,
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

            var bidderId = request.auth.credentials.id;
            var queryConfig = {
                name: 'bids_from_me',
                text: 'SELECT * FROM bids WHERE bidder_id = $1 AND deleted = false \
                       ORDER BY id DESC',
                values: [bidderId]
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
        path: options.basePath + '/bids/revoke',
        config: {
            auth: {
                strategy: 'token'
            },
            validate: {
                payload: {
                    id: Joi.string().regex(/^[0-9]+$/).max(19)
                }
            }
        },
        handler: function (request, reply) {

            var queryConfig = {
                name: 'bids_revoke',
                text: 'UPDATE bids SET status = 20, updated_at = now() ' +
                      'WHERE id = $1 AND bidder_id = $2 AND status = 0 AND deleted = false ' +
                      'RETURNING id',
                values: [request.payload.id, request.auth.credentials.id]
            };

            request.pg.client.query(queryConfig, function (err, result) {

                if (err) {
                    console.error(err);
                    request.pg.kill = true;
                    return reply(err);
                }

                if (result.rows.length === 0) {
                    return reply(Boom.badData(c.BID_REVOKE_FAILED));
                }

                reply(null, result.rows[0]);
            });
        }
    });

    // accept a bid. auth.
    server.route({
        method: 'POST',
        path: options.basePath + '/bids/accept',
        config: {
            auth: {
                strategy: 'token'
            },
            validate: {
                payload: {
                    id: Joi.string().regex(/^[0-9]+$/).max(19)
                }
            }
        },
        handler: internals.acceptBidHandler
    });

    next();
};


exports.register.attributes = {
    name: 'bids'
};


internals.createBidHandler = function (request, reply) {

    Async.auto({
        askerId: function (next) {

            var queryConfig = {
                name: 'order_creator_by_id',
                text: 'SELECT user_id FROM orders WHERE id = $1 AND deleted = false',
                values: [request.payload.order_id]
            };

            request.pg.client.query(queryConfig, function (err, result) {

                if (err) {
                    request.pg.kill = true;
                    return next(err);
                }

                if (result.rows.length === 0) {
                    return next(Boom.notFound(c.RECORD_NOT_FOUND));
                }

                next(null, result.rows[0].user_id);
            });
        },
        bidId: function (next) {

            var bidderId = request.auth.credentials.id;
            var p = request.payload;
            var queryConfig = {
                name: 'bids_create',
                text: 'INSERT INTO bids \
                           (bidder_id, order_id, price, note, expire_at, created_at, updated_at) VALUES \
                           ($1, $2, $3, $4, $5, now(), now()) \
                           RETURNING id',
                values: [bidderId, p.order_id, p.price, p.note, p.expire_at]
            };

            request.pg.client.query(queryConfig, function (err, result) {

                if (err) {
                    request.pg.kill = true;
                    return next(err);
                }

                if (result.rows.length === 0) {

                    return next(Boom.badData(c.QUERY_FAILED));
                }

                next(null, result.rows[0].id);
            });
        }
    }, function (err, results) {

        if (err) {
            console.error(err);
            return reply(err);
        }

        reply(null, { bid_id: results.bidId });

        // send notification to the asker
        var title = 'Received a bid: ' + request.auth.credentials.username + ' ask for $' + request.payload.price;
        Push.notify('joyy', results.askerId, title, title, function (error) {

            if (error) {
                console.error(error);
            }
        });
    });
};


internals.acceptBidHandler = function (request, reply) {

    var bidId = request.payload.id;
    Async.waterfall([
        function (callback) {

            var queryConfig = {
                name: 'bids_order_id_by_bid_id',
                text: 'SELECT order_id, bidder_id FROM bids WHERE id = $1 AND status = 0 AND deleted = false',
                values: [bidId]
            };

            request.pg.client.query(queryConfig, function (err, result) {
                if (err) {
                    request.pg.kill = true;
                    return callback(err);
                }

                if (result.rows.length === 0) {
                    return reply(Boom.badData(c.BID_UPDATE_FAILED));
                }

                callback(null, result.rows[0].order_id, result.rows[0].bidder_id);
            });
        },
        function (orderId, bidderId, callback) {

            request.pg.client.query('BEGIN', function(err) {
                if (err) {
                    request.pg.kill = true;
                    return callback(err);
                }

                callback(null, orderId, bidderId);
            });
        },
        function (orderId, bidderId, callback) {

            var queryText = 'UPDATE orders ' +
                      'SET winner_id = $1, status = 1, updated_at = now() ' +
                      'WHERE id = $2 AND user_id = $3 AND status = 0 ' +
                      'RETURNING id';
            var queryConfig = {
                name: 'orders_update_pending',
                text: queryText,
                values: [bidderId, orderId, request.auth.credentials.id]
            };

            request.pg.client.query(queryConfig, function (err, result) {

                if (err) {
                    request.pg.kill = true;
                    return callback(err);
                }

                if (result.rows.length === 0) {
                    return reply(Boom.badData(c.ORDER_UPDATE_FAILED));
                }

                callback(null, orderId);
            });
        },
        function (orderId, callback) {

            var queryConfig = {
                name: 'bids_accept',
                text: 'UPDATE bids ' +
                      'SET status = 1, updated_at = now() ' +
                      'WHERE id = $1 AND status = 0 ' +
                      'RETURNING bidder_id',
                values: [bidId]
            };

            request.pg.client.query(queryConfig, function (err, result) {

                if (err) {
                    request.pg.kill = true;
                    return callback(err);
                }

                callback(null, orderId, result.rows[0].bidder_id);
            });
        },
        function (orderId, winnerId, callback) {

            var queryConfig = {
                name: 'bids_reject_others',
                text: 'UPDATE bids ' +
                      'SET status = 10, updated_at = now() ' +
                      'WHERE order_id = $1 AND id <> $2 AND status = 0 ' +
                      'RETURNING bidder_id',
                values: [orderId, bidId]
            };

            request.pg.client.query(queryConfig, function (err, result) {

                if (err) {
                    request.pg.kill = true;
                    return callback(err);
                }

                callback(null, winnerId, result.rows);
            });
        },
        function (winnerId, losers, callback) {

            request.pg.client.query('COMMIT', function(err) {
                if (err) {
                    request.pg.kill = true;
                    callback(err);
                }

                callback(null, winnerId, losers);
            });
        }
    ], function (err, winnerId, losers) {

        if (err) {

            console.error(err);
            request.pg.client.query('ROLLBACK', function(rollbackErr) {
                if (rollbackErr) {
                    request.pg.kill = true;
                }

                reply(err);
            });
        }
        else {

            reply(null, { winner: winnerId });

            // send notification to the winner
            var title = request.auth.credentials.username + ' accepted your bid!';
            Push.notify('joyyor', winnerId, title, title, function (error) {

                if (error) {
                    console.error(error);
                }
            });

            // send notification to the losers
            console.info('losers = %j', losers);
        }
    });
};
