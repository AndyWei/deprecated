//  Copyright (c) 2015 Joyy Inc. All rights reserved.


var Async = require('async');
var AWS = require('aws-sdk');
var Bcrypt = require('bcrypt');
var Boom = require('boom');
var Config = require('../config');
var Const = require('./constants');
var Jwt  = require('jsonwebtoken');

var exports = module.exports = {};
var internals = {};

var params = {
    IdentityPoolId: Config.get('/aws/identifyPoolId'),
    Logins: {
        joyy: 0
    },
    TokenDuration: Config.get('/aws/identifyExpiresInSeconds')
};

internals.validateSimple = function (request, email, password, finish) {

    Async.auto({
        credentials: function (callback) {

            var queryConfig = {
                text: 'SELECT id, password, email, name FROM person WHERE email = $1 AND deleted = false',
                values: [email],
                name: 'person_by_email'
            };

            request.pg.client.query(queryConfig, function (err, result) {

                if (err) {
                    request.pg.kill = true;
                    return callback(err);
                }

                if (result.rowCount === 0) {
                    return callback(Boom.unauthorized(Const.PERSON_NOT_FOUND));
                }

                return callback(null, result.rows[0]);
            });
        },
        isValid: ['credentials', function (callback, results) {

            Bcrypt.compare(password, results.credentials.password, function (err, compareResult) {

                if (err) {
                    return callback(Boom.unauthorized(err));
                }

                results.credentials.password = password;
                return callback(null, compareResult);
            });
        }],
        cognito: ['credentials', function (callback, results) {

            params.Logins.joyy =  results.credentials.id;

            internals.cognitoidentity.getOpenIdTokenForDeveloperIdentity(params, function(err, data) {

                if (err) {
                    console.error(err);
                    return callback(err);
                }
                return callback(null, data);
            });
        }]
    }, function (err, results) {

        if (err || !results.isValid) {
            console.log(err);
            return finish(err, false);
        }

        results.credentials.cognito = results.cognito;
        return finish(null, true, results.credentials);
    });
};


internals.validateToken = function (token, callback) {

    var key = Config.get('/jwt/key');
    Jwt.verify(token, key, function(err, decoded) {

        if (err) {
            console.log(err);
            return callback(Boom.unauthorized(Const.AUTH_TOKEN_INVALID));
        }

        // Authenticated
        return callback(null, true, decoded);
    });
};


exports.register = function (server, options, next) {

    server.auth.strategy('simple', 'basic', {
        validateFunc: internals.validateSimple
    });

    server.auth.strategy('token', 'bearer-access-token', {
        validateFunc: internals.validateToken
    });

    AWS.config.update({
        accessKeyId: Config.get('/aws/accessKeyId'),
        secretAccessKey: Config.get('/aws/secretAccessKey'),
        region: Config.get('/aws/region')
    });

    internals.cognitoidentity = new AWS.CognitoIdentity({apiVersion: '2014-06-30'});

    next();
};


exports.register.attributes = {
    name: 'authenticate'
};
