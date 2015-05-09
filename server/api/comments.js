var Async = require('async');
var Boom = require('boom');
var Hoek = require('hoek');
var Joi = require('joi');
var Push = require('../push');
var c = require('../constants');

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


    // get all comments of the given order. no auth.
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
            var select = 'SELECT user_id, username, order_id, is_from_joyyor, to_username, contents FROM comments ';
            var where = 'WHERE id > $1 AND deleted = false AND order_id IN ($2';
            var sort = 'ORDER BY id ASC';

            for (var i = 0, il = request.query.order_id.length - 1; i < il; ++i) {
                where += ', $' + (i + 3).toString();
            }
            where += ') ';

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
                    peer_id: Joi.string().regex(/^[0-9]+$/).max(19),  // It should be the user_id of the parent_id, this field will be used for push notification.
                    is_from_joyyor: Joi.number().min(0).max(1),
                    is_to_joyyor: Joi.number().min(0).max(1),
                    to_username: Joi.string().token().max(50),
                    contents: Joi.string().max(1000)
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
                           (user_id, username, order_id, is_from_joyyor, to_username, contents, created_at, updated_at) VALUES \
                           ($1, $2, $3, $4, $5, $6, now(), now()) \
                           RETURNING id',
                values: [userId, username, p.order_id, isFromJoyyor, p.to_username, p.contents]
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

        // send notification to the peer
        var app = isToJoyyor ? 'joyyor' : 'joyy';
        var title = request.auth.credentials.username + ': ' + request.payload.contents;
        Push.notify(app, request.payload.peer_id, title, title, function (error) {

            if (error) {
                console.error(error);
            }
        });

        reply(null, commentId);
    });
};
