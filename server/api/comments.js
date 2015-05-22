var Async = require('async');
var Boom = require('boom');
var Cache = require('../cache');
var Hoek = require('hoek');
var Joi = require('joi');
var Push = require('../push');
var Utils = require('../utils');
var c = require('../constants');
var _ = require('underscore');

var internals = {};

exports.register = function (server, options, next) {

    options = Hoek.applyToDefaults({ basePath: '' }, options);

    // get a single comment by id. no auth.
    server.route({
        method: 'GET',
        path: options.basePath + '/comments/{id}',
        config: {
            validate: {
                params: {
                    id: Joi.string().regex(/^[0-9]+$/).max(19)
                }
            }
        },
        handler: function (request, reply) {

            var queryConfig = {
                name: 'comments_by_id',
                text: 'SELECT * FROM comments WHERE id = $1 AND deleted = false',
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


    // get all comments of the orders. no auth.
    server.route({
        method: 'GET',
        path: options.basePath + '/comments/of/orders',
        config: {
            validate: {
                query: {
                    after: Joi.string().regex(/^[0-9]+$/).max(19).default('0'),
                    order_id: Joi.array().single(true).unique().items(Joi.string().regex(/^[0-9]+$/).max(19))
                }
            }
        },
        handler: function (request, reply) {

            var queryValues = [request.query.after];
            var select = 'SELECT * FROM comments ';
            var where = 'WHERE id > $1 AND deleted = false AND order_id IN ' + Utils.parametersString(2, request.query.order_id.length);
            var sort = 'ORDER BY id ASC LIMIT 200';

            queryValues = queryValues.concat(request.query.order_id);

            var queryConfig = {
                name: 'comments_of_orders',
                text: select + where + sort,
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


    // get all comments count of the orders. no auth.
    server.route({
        method: 'GET',
        path: options.basePath + '/comments/count/of/orders',
        config: {
            validate: {
                query: {
                    order_id: Joi.array().single(true).unique().items(Joi.string().regex(/^[0-9]+$/).max(19))
                }
            }
        },
        handler: function (request, reply) {

            Cache.mget(c.ORDER_COMMENTS_COUNT_CACHE, request.query.order_id, function (err, results) {

                if (err) {
                    console.error(err);
                    return reply(err);
                }

                var zeroFilledResults = _.map(results, function (result) {
                    return (result === null) ? '0' : result;
                });

                reply(null, zeroFilledResults);
            });
        }
    });


    // Create an comment. auth.
    server.route({
        method: 'POST',
        path: options.basePath + '/comments',
        config: {
            auth: {
                strategy: 'token'
            },
            validate: {
                payload: {
                    order_id: Joi.string().regex(/^[0-9]+$/).max(19),
                    to_user_id: Joi.string().regex(/^[0-9]+$/).max(19),  // It should be the user_id of the parent_id, this field will be used for push notification.
                    is_from_joyyor: Joi.number().min(0).max(1),
                    is_to_joyyor: Joi.number().min(0).max(1),
                    to_username: Joi.string().token().max(50),
                    body: Joi.string().max(1000)
                }
            }
        },
        handler: internals.createCommentHandler
    });

    next();
};


exports.register.attributes = {
    name: 'comments'
};


internals.createCommentHandler = function (request, reply) {

    var p = request.payload;
    var userId = request.auth.credentials.id;
    var username = request.auth.credentials.username;
    var isFromJoyyor = (p.is_from_joyyor === 1);
    var isToJoyyor = (p.is_to_joyyor === 1);

    Async.waterfall([
        function (callback) {

            var queryConfig = {
                name: 'comments_create',
                text: 'INSERT INTO comments \
                           (user_id, username, order_id, is_from_joyyor, to_username, body, created_at, updated_at) VALUES \
                           ($1, $2, $3, $4, $5, $6, now(), now()) \
                           RETURNING id',
                values: [userId, username, p.order_id, isFromJoyyor, p.to_username, p.body]
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
    ], function (err, commentId) {

        if (err) {
            console.error(err);
            return reply(err);
        }

        // early reply the submitter
        reply(null, commentId);

        // update engaged order list
        Cache.lpush(c.ENGAGED_ORDER_ID_CACHE, userId, p.order_id, function (error) {

            if (error) {
                console.error(error);
            }
        });

        // increase the comments count
        Cache.incr(c.ORDER_COMMENTS_COUNT_CACHE, p.order_id, function (error) {

            if (error) {
                console.error(error);
            }
        });

        // send notification to the to_user_id
        var app = isToJoyyor ? 'joyyor' : 'joyy';
        var title = request.auth.credentials.username + ': ' + request.payload.body;
        Push.notify(app, p.to_user_id, title, title, function (error) {

            if (error) {
                console.error(error);
            }
        });
    });
};
