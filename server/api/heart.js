var Async = require('async');
var Boom = require('boom');
var Cache = require('../cache');
var Const = require('../constants');
var Hoek = require('hoek');
var Joi = require('joi');
var _ = require('underscore');


exports.register = function (server, options, next) {

    options = Hoek.applyToDefaults({ basePath: '' }, options);

    // get all heart received by the current user. auth.
    server.route({
        method: 'GET',
        path: options.basePath + '/heart/me',
        config: {
            auth: {
                strategy: 'token'
            },
            validate: {
                query: {
                    status: Joi.number().min(0).max(100).default(0),
                    before: Joi.string().regex(/^[0-9]+$/).max(19).default(Const.MAX_ID)
                }
            }
        },
        handler: function (request, reply) {

            var q = request.query;

            var select = 'SELECT sender FROM heart ';
            var where  = 'WHERE receiver = $1 AND status = $2 AND id < $3 AND deleted = false ';
            var sort   = 'ORDER BY id DESC LIMIT 10';
            var queryConfig = {
                name: 'heart_me',
                text: select + where + sort,
                values: [request.auth.credentials.id, q.status, q.before]
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


    // get all heart given by the current user. auth.
    server.route({
        method: 'GET',
        path: options.basePath + '/heart/my',
        config: {
            auth: {
                strategy: 'token'
            },
            validate: {
                query: {
                    status: Joi.number().min(0).max(100).default(0),
                    before: Joi.string().regex(/^[0-9]+$/).max(19).default(Const.MAX_ID)
                }
            }
        },
        handler: function (request, reply) {

            var q = request.query;

            var select = 'SELECT receiver, status FROM heart ';
            var where  = 'WHERE sender = $1 AND status = $2 AND id < $3 AND deleted = false ';
            var sort   = 'ORDER BY id DESC LIMIT 30';
            var queryConfig = {
                name: 'heart_my',
                text: select + where + sort,
                values: [request.auth.credentials.id, q.status, q.before]
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


    // POST a heart to someone. auth.
    server.route({
        method: 'POST',
        path: options.basePath + '/heart',
        config: {
            auth: {
                strategy: 'token'
            },
            validate: {
                payload: {
                    receiver: Joi.string().regex(/^[0-9]+$/).max(19).required()
                }
            }
        },
        handler: function (request, reply) {

            var p = request.payload;
            var personId = request.auth.credentials.id;

            if (personId.toString() === p.receiver) {
                return reply(Boom.notAcceptable(Const.HEART_NOT_ALLOWED));
            }

            Async.auto({

                heart: function (callback) {
                    var queryConfig = {
                        name: 'heart_create',
                        text: 'INSERT INTO heart (sender, receiver, ct, ut)  ' +
                              'VALUES ($1, $2, $3, $4) ' +
                              'RETURNING id',
                        values: [personId, p.receiver, _.now(), _.now()]
                    };

                    request.pg.client.query(queryConfig, function (err, result) {

                        if (err) {
                            console.error(err);
                            request.pg.kill = true;
                            return callback(err);
                        }

                        if (result.rows.length === 0) {
                            return callback(Boom.badRequest(Const.HEART_CREATE_FAILED));
                        }

                        return callback(null, result.rows[0]);
                    });
                },
                person: ['heart', function (callback) {
                    var queryConfig = {
                        name: 'person_increase_hearts',
                        text: 'UPDATE person SET hearts = hearts + 1, ut = $1 ' +
                              'WHERE id = $2 AND deleted = false ' +
                              'RETURNING cell, hearts, friends',
                        values: [_.now(), p.receiver]
                    };

                    request.pg.client.query(queryConfig, function (err, result) {

                        if (err) {
                            console.error(err);
                            request.pg.kill = true;
                            return callback(err);
                        }

                        if (result.rows.length === 0) {
                            return callback(Boom.badRequest(Const.PERSON_INCREASE_HEART_COUNT_FAILED));
                        }

                        return callback(null, result.rows[0]);
                    });
                }],
                cache: ['person', function (callback, results) {

                    var receiver = results.person;
                    var score = (receiver.hearts * 5) + (receiver.friends * 10);
                    Cache.zadd(Const.CELL_PERSON_SETS, receiver.cell, score, p.receiver, function (err) {
                        if (err) {
                            console.error(err); // since DB records is updated, do not callback(err) in case of cache failure
                        }
                        return callback(null);
                    });
                }]
            }, function (err, results) {

                if (err) {
                    console.error(err);
                    return reply(err);
                }

                return reply(null, results.heart);
            });
        }
    });

    next();
};


exports.register.attributes = {
    name: 'heart'
};
