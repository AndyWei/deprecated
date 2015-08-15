var Async = require('async');
var Bcrypt = require('bcrypt');
var Boom = require('boom');
var Config = require('../config');
var Const = require('./constants');
var Jwt  = require('jsonwebtoken');

var exports = module.exports = {};
var internals = {};


internals.validateSimple = function (request, email, password, finish) {

    Async.waterfall([
        function (callback) {

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
        function (person, callback) {

            Bcrypt.compare(password, person.password, function (err, isValid) {

                if (err) {
                    return callback(Boom.unauthorized(err));
                }

                person.password = password;
                return callback(null, isValid, person);
            });
        }
    ], function (err, isValid, person) {

        if (err || !isValid) {
            console.error(err);
            return finish(err, false);
        }

        return finish(err, isValid, person);
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

    next();
};


exports.register.attributes = {
    name: 'authenticate'
};
