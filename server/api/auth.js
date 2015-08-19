//  Copyright (c) 2015 Joyy, Inc. All rights reserved.
// Provide auth API for ejabberd servers

var Async = require('async');
var Bcrypt = require('bcrypt');
var Const = require('../constants');
var Hoek = require('hoek');
var Joi = require('joi');
var _ = require('lodash');


function isNumeric(value) {
    return /^\d+$/.test(value);
}


exports.register = function (server, options, next) {

    options = Hoek.applyToDefaults({ basePath: '' }, options);

    // check if a credential is valid.
    server.route({
        method: 'POST',
        path: options.basePath + '/auth/credential',
        config: {
            validate: {
                payload: {
                    jid: Joi.string().email(),
                    password: Joi.string().min(4).max(100).required()
                }
            }
        },
        handler: function (request, reply) {

            var fail = {
                success: false,
                message: 'invalid username or credential'
            };

            var jid = request.payload.jid.split('@');
            var personId = jid[0];
            var domain = jid[1];

            if (!isNumeric(personId) || !_.isEqual(domain, Const.IM_DOMAIN)) {
                return reply(null, fail);
            }

            Async.waterfall([
                function (callback) {

                    var queryConfig = {
                        text: 'SELECT password FROM person WHERE id = $1 AND deleted = false',
                        values: [personId],
                        name: 'person_password_by_id'
                    };

                    request.pg.client.query(queryConfig, function (err, result) {

                        if (err) {
                            request.pg.kill = true;
                            return callback(err);
                        }

                        if (result.rowCount === 0) {
                            return callback(Const.PERSON_NOT_FOUND);
                        }

                        return callback(null, result.rows[0].password);
                    });
                },
                function (password, callback) {

                    Bcrypt.compare(request.payload.password, password, function (err, isValid) {

                        if (err) {
                            return callback(err);
                        }

                        return callback(null, isValid);
                    });
                }
            ], function (err, isValid) {

                if (err || !isValid) {
                    console.error(err);
                    return reply(null, fail);
                }

                var success = {
                    success: true
                };
                return reply(null, success);
            });
        }
    });

        // check if an username is valid.
    server.route({
        method: 'POST',
        path: options.basePath + '/auth/username',
        config: {
            validate: {
                payload: {
                    jid: Joi.string().email()
                }
            }
        },
        handler: function (request, reply) {

            var fail = {
                success: false,
                message: 'invalid username'
            };

            var jid = request.payload.jid.split('@');
            var personId = jid[0];
            var domain = jid[1];
            if (!isNumeric(personId) || !_.isEqual(domain, Const.IM_DOMAIN)) {
                return reply(null, fail);
            }

            Async.waterfall([
                function (callback) {

                    var queryConfig = {
                        text: 'SELECT password FROM person WHERE id = $1 AND deleted = false',
                        values: [personId],
                        name: 'person_password_by_id'
                    };

                    request.pg.client.query(queryConfig, function (err, result) {

                        if (err) {
                            request.pg.kill = true;
                            return callback(err);
                        }

                        if (result.rowCount === 0) {
                            return callback(Const.PERSON_NOT_FOUND);
                        }

                        return callback(null);
                    });
                }
            ], function (err) {

                if (err) {
                    console.error(err);
                    return reply(null, fail);
                }

                var success = {
                    success: true
                };
                return reply(null, success);
            });
        }
    });

    next();
};


exports.register.attributes = {
    name: 'auth'
};
