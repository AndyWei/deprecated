//  Copyright (c) 2015 Joyy Inc. All rights reserved.


var Async = require('async');
var AWS = require('aws-sdk');
var Bcrypt = require('bcrypt');
var Boom = require('boom');
var Config = require('../../config');
var Const = require('../constants');
var Hoek = require('hoek');
var Joi = require('joi');
var Jwt  = require('jsonwebtoken');
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

    // Existing person sign in
    server.route({
        method: 'GET',
        path: options.basePath + '/signin',
        config: {
            auth: {
                strategy: 'simple'
            }
        },
        handler: function (request, reply) {

            var personId = request.auth.credentials.id;
            Async.auto({
                jwt: function (callback) {

                    var token = internals.createJwtToken(personId);
                    return callback(null, token);
                }
            }, function (err, results) {

                if (err) {
                    console.error(err);
                    return reply(err);
                }

                var response = request.auth.credentials;
                response.token = results.jwt;

                return reply(null, response);
            });
        }
    });

    // New person sign up
    server.route({
        method: 'POST',
        path: options.basePath + '/signup',
        config: {
            validate: {
                payload: {
                    email: Joi.string().email().lowercase().min(3).max(30).required(),
                    password: Joi.string().min(4).max(100).required()
                }
            },
            pre: [{
                assign: 'emailCheck',
                method: internals.emailChecker
            }]
        },
        handler: internals.signup
    });


    // Existing person get cognito token
    server.route({
        method: 'GET',
        path: options.basePath + '/cognito',
        config: {
            auth: {
                strategy: 'token'
            }
        },
        handler: function (request, reply) {

            var tokenDuration = Config.get('/aws/identifyExpiresInSeconds');
            var params = {
                IdentityPoolId: Config.get('/aws/identifyPoolId'),
                Logins: {
                    joyy: request.auth.credentials.id
                },
                TokenDuration: tokenDuration
            };

            internals.cognitoidentity.getOpenIdTokenForDeveloperIdentity(params, function(err, data) {

                if (err) {
                    console.error(err);
                    return reply(err);
                }

                data.tokenDuration = tokenDuration;
                return reply(null, data);
            });
        }
    });

    next();
};


exports.register.attributes = {
    name: 'sign'
};


internals.emailChecker = function (request, reply) {

    var queryConfig = {
        text: 'SELECT id FROM person WHERE email = $1 AND deleted = false',
        values: [request.payload.email],
        name: 'person_select_id_by_email'
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

    var email = request.payload.email;
    var name = email.substring(0, 3); // auto given name is the first 3 chars of email

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
                          '(email, name, password, ct, ut) VALUES ' +
                          '($1, $2, $3, $4, $5) ' +
                          'RETURNING id',
                values: [email, name, results.password, _.now(), _.now()],
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

        var message = {
            id: results.personId,
            email: email,
            name: name,
            password: request.payload.password,
            token: internals.createJwtToken(results.personId)
        };

        console.log('user created. email=%s, name = %s', email, name);
        return reply(null, message).code(201);
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
