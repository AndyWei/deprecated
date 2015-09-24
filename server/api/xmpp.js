// Copyright (c) 2015 Joyy Inc. All rights reserved.
// Provide endpoints for the MongooseIM XMPP servers

var Config = require('../../config');
var Hoek = require('hoek');
var Joi = require('joi');
var Jwt  = require('jsonwebtoken');
var Push = require('../push');
var _ = require('lodash');


exports.register = function (server, options, next) {

    options = Hoek.applyToDefaults({ basePath: '' }, options);

    // Http auth endpoint to check if an user pasword is valid.
    // Refer to: https://github.com/esl/MongooseIM/wiki/HTTP-authentication-module
    // Note: we use personId from joyyserver as the username in joyy.im and the JWT token as joyy.im password
    server.route({
        method: 'GET',
        path: options.basePath + '/xmpp/check_password',
        config: {
            validate: {
                query: {
                    user: Joi.string().token().min(4).required(),
                    server: Joi.string().valid('joyy.im').required(),
                    pass: Joi.string().min(4).max(200).required()
                }
            }
        },
        handler: function (request, reply) {

            var key = Config.get('/jwt/key');
            Jwt.verify(request.query.pass, key, function(err, decoded) {

                if (err) {
                    console.log(err);
                    return reply(null, false);
                }

                // The pass token is good, but user id not match, which means the token is stolen from another user
                if (!_.isEqual(request.query.user, decoded.username)) {
                    console.log('Failure: authentication of user %s failed due to username mismatch', request.query.user);
                    return reply(null, false);
                }

                // Authenticated passed
                console.log('Success: authentication of user %s passed', request.query.user);
                return reply(null, true);
            });
        }
    });

    // check if an user exists.
    server.route({
        method: 'GET',
        path: options.basePath + '/xmpp/user_exists',
        config: {
            validate: {
                query: {
                    user: Joi.string().token().min(4).required(),
                    server: Joi.string().valid('joyy.im').required(),
                    pass: Joi.any().optional()
                }
            }
        },
        handler: function (request, reply) {

            var queryConfig = {
                text: 'SELECT id FROM person WHERE username = $1 AND deleted = false',
                values: [request.query.user],
                name: 'person_select_id_by_username'
            };
            request.pg.client.query(queryConfig, function (err, result) {

                if (err) {
                    console.error(err);
                    request.pg.kill = true;
                    return reply(err);
                }

                if (result.rowCount === 0) {
                    return reply(null, false);
                }

                return reply(null, true);
            });
        }
    });


    server.route({
        method: 'POST',
        path: options.basePath + '/xmpp/push',
        config: {
            validate: {
                payload: {
                    from: Joi.string().token().min(4).required(),
                    to: Joi.string().token().min(4).required(),
                    message: Joi.string().required()
                }
            }
        },
        handler: function (request, reply) {

            var fromUser = request.payload.from;
            var toUser = request.payload.to;

            Push.notify(request, fromUser, toUser, request.payload.message, 'xmpp');
            return reply(null);
        }
    });

    next();
};


exports.register.attributes = {
    name: 'xmpp'
};
