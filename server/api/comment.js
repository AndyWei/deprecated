var Async = require('async');
var Boom = require('boom');
var Cache = require('../cache');
var Hoek = require('hoek');
var Joi = require('joi');
var c = require('../constants');
var _ = require('underscore');


var internals = {};

exports.register = function (server, options, next) {

    options = Hoek.applyToDefaults({ basePath: '' }, options);

    // get comment of media. no auth.
    server.route({
        method: 'GET',
        path: options.basePath + '/comment',
        config: {
            validate: {
                query: {
                    media_id: Joi.string().regex(/^[0-9]+$/).max(19).required(),
                    after: Joi.string().regex(/^[0-9]+$/).max(19).default('0'),
                    before: Joi.string().regex(/^[0-9]+$/).max(19).default(c.MAX_ID)
                }
            }
        },
        handler: function (request, reply) {

            var q = request.query;

            var select = 'SELECT id, owner_id, content, created_at FROM comment ';
            var where = 'WHERE id > $1 AND id < $2 AND media_id = $3 AND deleted = false ';
            var order = 'ORDER BY id ASC ';
            var limit = 'LIMIT 20';

            var queryConfig = {
                name: 'comments_of_media',
                text: select + where + order + limit,
                values: [q.after, q.before, q.media_id]
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
                    media_id: Joi.string().regex(/^[0-9]+$/).max(19).required(),
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
                           (owner_id, media_id, content, created_at) VALUES \
                           ($1, $2, $3, $4) \
                           RETURNING id',
                values: [pid, p.media_id, p.content, _.now()]
            };

            request.pg.client.query(queryConfig, function (err, result) {

                if (err) {
                    request.pg.kill = true;
                    return next(err);
                }

                if (result.rows.length === 0) {
                    return next(Boom.badData(c.COMMENT_CREATE_FAILED));
                }

                return next(null, result.rows[0]);
            });
        },
        updateCache: ['commentId', function (next) {

            // push this comment content to cache and increase the comment count
            Cache.enqueue(c.COMMENT_CACHE, c.COMMENT_COUNT_CACHE, p.media_id, p.content, function (error) {
                if (error) {
                    // Just log the error, do not call next(error) since caching is a kind of "try our best" thing
                    console.error(error);
                }

                return next(null);
            });
        }]
    }, function (err, results) {

        if (err) {
            console.error(err);
            return reply(err);
        }

        return reply(null, results.commentId);
    });
};
