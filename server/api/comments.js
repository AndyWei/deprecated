var Async = require('async');
var Boom = require('boom');
var Cache = require('../cache');
var Hoek = require('hoek');
var Joi = require('joi');
var Push = require('../push');
var Utils = require('../utils');
var c = require('../constants');
var _ = require('underscore');
_.str = require('underscore.string');


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
                // WARNING!!!: the queryConfig MUST NOT have a name field since it has vaiable number of parameters
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

    Async.auto({
        commentId: function (next) {

            var queryConfig = {
                name: 'comments_create',
                text: 'INSERT INTO comments \
                           (user_id, username, order_id, body, created_at, updated_at) VALUES \
                           ($1, $2, $3, $4, now(), now()) \
                           RETURNING id',
                values: [userId, username, p.order_id, p.body]
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
        },
        customerId: function (next) {

            var queryConfig = {
                name: 'order_user_id_by_id',
                text: 'SELECT user_id FROM orders WHERE id = $1 AND deleted = false',
                values: [p.order_id]
            };

            request.pg.client.query(queryConfig, function (err, result) {

                if (err) {
                    request.pg.kill = true;
                    return next(err);
                }

                if (result.rows.length === 0) {
                    return next(Boom.notFound(c.ORDER_NOT_FOUND));
                }

                next(null, result.rows[0].user_id);
            });
        },
        recipientIds: function (next) {

            // p.body = '@andy @ping @jack whats up?'
            var words = _.str.words(p.body);                                               // words   = ['@andy', '@ping', '@jack', 'whats', 'up?']
            var handles = _.filter(words, function (word) { return word[0] === '@'; });    // handles = ['@andy', '@ping', '@jack']
            var usernames = _.map(handles, function (handle) { return handle.slice(1); }); // usernames=['andy', 'ping', 'jack']

            Cache.mget(c.USER_NAME_ID_CACHE, usernames, function (err, userIds) {
                if (err) {
                    return next(err);
                }

                var validUserIds = _.filter(userIds, function (id) { return id !== null; });
                next(null, validUserIds);
            });
        }
    }, function (err, results) {

        if (err) {
            console.error(err);
            return reply(err);
        }

        // early reply the submitter
        reply(null, { id: results.commentId });

        // increase the comments count
        Cache.incr(c.ORDER_COMMENTS_COUNT_CACHE, p.order_id, function (error) {
            if (error) {
                console.error(error);
            }
        });

        // send notification to recipientIds in joyyor
        var title = request.auth.credentials.username + ': ' + request.payload.body;
        Push.mnotify('joyyor', results.recipientIds, title, title);

        // send notification to the customer
        if (results.customerId !== userId.toString()) {
            Push.notify('joyy', results.customerId, title, title, function (error) {
                if (error) {
                    console.error(error);
                }
            });
        }
    });
};
