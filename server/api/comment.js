var Async = require('async');
var Boom = require('boom');
var Cache = require('../cache');
var Hoek = require('hoek');
var Joi = require('joi');
var Const = require('../constants');
var _ = require('underscore');

var internals = {};


exports.register = function (server, options, next) {

    options = Hoek.applyToDefaults({ basePath: '' }, options);

    // get comment of post. no auth.
    server.route({
        method: 'GET',
        path: options.basePath + '/comment',
        config: {
            validate: {
                query: {
                    post: Joi.string().regex(/^[0-9]+$/).max(19).required(),
                    after: Joi.string().regex(/^[0-9]+$/).max(19).default('0'),
                    before: Joi.string().regex(/^[0-9]+$/).max(19).default(Const.MAX_ID)
                }
            }
        },
        handler: function (request, reply) {

            var q = request.query;

            var select = 'SELECT id, owner, content, ct FROM comment ';
            var where = 'WHERE id > $1 AND id < $2 AND post = $3 AND deleted = false ';
            var order = 'ORDER BY id ASC ';
            var limit = 'LIMIT 20';

            var queryConfig = {
                name: 'comments_of_post',
                text: select + where + order + limit,
                values: [q.after, q.before, q.post]
            };

            request.pg.client.query(queryConfig, function (err, result) {

                if (err) {
                    console.error(err);
                    request.pg.kill = true;
                    return reply(err);
                }

                return reply(null, result.rows);
            });
        }
    });


    // Create an comment. auth.
    server.route({
        method: 'POST',
        path: options.basePath + '/comment',
        config: {
            auth: {
                strategy: 'token'
            },
            validate: {
                payload: {
                    post: Joi.string().regex(/^[0-9]+$/).max(19).required(),
                    content: Joi.string().max(2000).required()
                }
            }
        },
        handler: internals.createCommentHandler
    });

    next();
};


exports.register.attributes = {
    name: 'comment'
};


internals.createCommentHandler = function (request, reply) {

    var p = request.payload;
    var pid = request.auth.credentials.id;

    Async.auto({
        commentId: function (next) {

            var queryConfig = {
                name: 'comment_create',
                text: 'INSERT INTO comment \
                           (owner, post, content, ct) VALUES \
                           ($1, $2, $3, $4) \
                           RETURNING id',
                values: [pid, p.post, p.content, _.now()]
            };

            request.pg.client.query(queryConfig, function (err, result) {

                if (err) {
                    request.pg.kill = true;
                    return next(err);
                }

                if (result.rows.length === 0) {
                    return next(Boom.badData(Const.COMMENT_CREATE_FAILED));
                }

                return next(null, result.rows[0]);
            });
        },
        updateCache: ['commentId', function (next) {

            Cache.pushlist(Const.POST_COMMENT_LISTS, p.post, p.content);
            Cache.hincrby(Const.POST_HASHES, p.post, 'comments', 1, function (err, result) {
                if (err) {
                    return next(err);
                }

                return next(null, result);
            });
        }]
    }, function (err, results) {

        if (err) {
            console.error(err);
            return reply(err);
        }

        return reply(null, { comments: results.updateCache });
    });
};
