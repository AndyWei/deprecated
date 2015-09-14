//  Copyright (c) 2015 Joyy Inc. All rights reserved.

var Async = require('async');
var AWS = require('aws-sdk');
var Bcrypt = require('bcrypt');
var Boom = require('boom');
var Cache = require('../cache');
var Config = require('../../config');
var Const = require('../constants');
var Hoek = require('hoek');
var Joi = require('joi');
var Jwt  = require('jsonwebtoken');
var Plivo = require('plivo');
var Twilio = require('twilio');
var _ = require('lodash');

var internals = {};

exports.register = function (server, options, next) {

    options = Hoek.applyToDefaults({ basePath: '' }, options);

    AWS.config.update({
        accessKeyId: Config.get('/aws/accessKeyId'),
        secretAccessKey: Config.get('/aws/secretAccessKey'),
        region: Config.get('/aws/region')
    });

    internals.cognitoidentity = new AWS.CognitoIdentity({apiVersion: '2014-06-30'});
    internals.awsTokenDuration = Config.get('/aws/identifyExpiresInSeconds');
    internals.apiTokenDuration = Config.get('/jwt/expiresInMinutes') * 60;

    internals.plivo = new Plivo.RestAPI({
        authId: Config.get('/plivo/authId'),
        authToken: Config.get('/plivo/authToken')
    });

    internals.twilio = new Twilio.RestClient(
        Config.get('/twilio/sid'),
        Config.get('/twilio/token')
    );

    // Get a verification code to verify phone number
    server.route({
        method: 'GET',
        path: options.basePath + '/credential/vcode',
        config: {
            validate: {
                query: {
                    phone: Joi.number().min(0).required(), // The E.164 phone number without the '+' prefix.
                    language: Joi.string().length(2).lowercase().optional() // The ISO 639-1 language code.
                }
            }
        },
        handler: function (request, reply) {

            var phoneNumber = request.query.phone.toString();
            var randomCode = _.random(1000, 9999);
            var messageBody = randomCode + ' is your Joyy verification code.';

            Async.auto({
                cache: function (callback) {

                    Cache.setex(Const.PHONE_VERIFICATION_PAIRS, request.query.phone, randomCode, function (err) {

                        if (err) {
                            return callback(err);
                        }

                        return callback(null);
                    });
                },
                sms: function (callback) {

                    // For phone numbers in China, Indonesia and UK, send SMS via twilio
                    if (_.startsWith(phoneNumber, '86') || _.startsWith(phoneNumber, '62') || _.startsWith(phoneNumber, '44')) {

                        var message = {
                            from: Config.get('/twilio/sourceNumber'),
                            to: '+' + phoneNumber,
                            body: messageBody
                        };
                        internals.twilio.sendMessage(message, function(err) {

                            if (err) {
                                return callback(err);
                            }
                            return callback(null);
                        });
                    }
                    else {
                        // For other countries, send SMS via plivo
                        var params = {
                            src: Config.get('/plivo/sourceNumber'),
                            dst: phoneNumber,
                            text: messageBody
                        };
                        internals.plivo.send_message(params, function(status, response) {

                            if (status < 200 || status >= 300) {
                                return callback(response);
                            }
                            return callback(null);
                        });
                    }
                }
            }, function (err) {

                if (err) {
                    console.error(err);
                    return reply(err);
                }

                return reply(null);
            });
        }
    });


    // Existing person sign in
    server.route({
        method: 'GET',
        path: options.basePath + '/credential/signin',
        config: {
            auth: {
                strategy: 'simple'
            }
        },
        handler: function (request, reply) {

            Async.auto({
                jwt: function (callback) {

                    var token = internals.createJwtToken(request.auth.credentials.id);
                    return callback(null, token);
                }
            }, function (err, results) {

                if (err) {
                    console.error(err);
                    return reply(err);
                }

                var response = {
                    id: request.auth.credentials.id,
                    phone: request.auth.credentials.phone,
                    username: request.auth.credentials.username,
                    token: results.jwt,
                    tokenDuration: internals.apiTokenDuration
                };

                return reply(null, response);
            });
        }
    });

    // New person sign up
    server.route({
        method: 'POST',
        path: options.basePath + '/credential/signup',
        config: {
            validate: {
                payload: {
                    phone: Joi.number().min(0).required(),
                    password: Joi.string().min(4).max(100).required()
                }
            },
            pre: [{
                assign: 'phoneCheck',
                method: internals.phoneChecker
            }]
        },
        handler: internals.signup
    });


    // Existing person get cognito token
    server.route({
        method: 'GET',
        path: options.basePath + '/credential/cognito',
        config: {
            auth: {
                strategy: 'token'
            }
        },
        handler: function (request, reply) {

            var params = {
                IdentityPoolId: Config.get('/aws/identifyPoolId'),
                Logins: {
                    joyy: request.auth.credentials.id
                },
                TokenDuration: internals.awsTokenDuration
            };

            internals.cognitoidentity.getOpenIdTokenForDeveloperIdentity(params, function(err, data) {

                if (err) {
                    console.error(err);
                    return reply(err);
                }

                data.tokenDuration = internals.awsTokenDuration;
                return reply(null, data);
            });
        }
    });

    next();
};


exports.register.attributes = {
    name: 'credential'
};


internals.phoneChecker = function (request, reply) {

    var queryConfig = {
        text: 'SELECT id FROM person WHERE phone = $1 AND deleted = false',
        values: [request.payload.phone],
        name: 'person_select_id_by_phone'
    };

    request.pg.client.query(queryConfig, function (err, result) {

        if (err) {
            console.error(err);
            request.pg.kill = true;
            return reply(err);
        }

        if (result.rows.length > 0) {
            return reply(Boom.conflict(Const.EMAIL_IN_USE));
        }

        reply(true);
    });
};


internals.signup = function (request, reply) {

    var phone = request.payload.phone;
    var username = phone.substring(0, 3); // auto given name is the first 3 chars of phone

    Async.auto({
        salt: function (callback) {

            Bcrypt.genSalt(Const.BCRYPT_ROUND, function(err, salt) {
                callback(err, salt);
            });
        },
        password: ['salt', function (callback, results) {

            Bcrypt.hash(request.payload.password, results.salt, function(err, hash) {
                 callback(err, hash);
            });
        }],
        personId: ['password', function (callback, results) {

            var queryConfig = {
                text: 'INSERT INTO person ' +
                          '(phone, username, password, ct, ut) VALUES ' +
                          '($1, $2, $3, $4, $5) ' +
                          'RETURNING id',
                values: [phone, username, results.password, _.now(), _.now()],
                name: 'person_signup'
            };

            request.pg.client.query(queryConfig, function (err, queryResult) {
                if (err) {
                    request.pg.kill = true;
                    return callback(err);
                }

                if (queryResult.rowCount === 0) {
                    return callback(Boom.badImplementation(Const.USER_CREATE_FAILED));
                }

                callback(err, queryResult.rows[0].id);
            });
        }]
    }, function (err, results) {

        if (err) {
            console.error(err);
            return reply(err);
        }

        var response = {
            id: results.personId,
            phone: phone,
            username: username,
            token: internals.createJwtToken(results.personId),
            tokenDuration: 60 * Config.get('/jwt/expiresInMinutes')
        };

        console.log('user created. phone=%s, username = %s', phone, username);
        return reply(null, response).code(201);
    });
};

internals.getOrgFromEmail = function (email) {

    // email = john.smith@apple.com.cn
    var domain = email.substring(email.lastIndexOf('@') + 1); // apple.com.cn
    var fields = domain.split('.');                           // [apple, com, cn]
    var orgType;
    switch (fields[1]) {
        case 'com':
            orgType = Const.OrgType.COM;
            break;
        case 'edu':
            orgType = Const.OrgType.EDU;
            break;
        case 'org':
            orgType = Const.OrgType.ORG;
            break;
        case 'gov':
            orgType = Const.OrgType.GOV;
            break;
        default:
            orgType = Const.OrgType.OTHER;
    }

    var org = {
        name: fields[0],
        type: orgType
    };
    return org;
};


internals.createJwtToken = function (personId) {

    if (!_.isString(personId)) {
         personId = personId.toString();
    }

    var obj = { id: personId };
    var key = Config.get('/jwt/key');
    var options = { expiresInMinutes: Config.get('/jwt/expiresInMinutes')};
    var token = Jwt.sign(obj, key, options);

    return token;
};
