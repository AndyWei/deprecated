var Async = require('async');
var Bcrypt = require('bcrypt');
var Boom = require('boom');
var Config = require('../config');
var Pg = require('pg').native;
var Token = require('./token');
var c = require('./constants');


var validateSimple = function (email, password, finish) {

    Async.waterfall([
        function (callback) {

            var db = Config.get('/db/connectionString');
            Pg.connect(db, function (err, client, done) {

                callback(err, client, done);
            });
        },
        function (client, done, callback) {

            var queryConfig = {
                text: 'SELECT id, username, password, email FROM users WHERE email = $1',
                values: [email],
                name: 'users_select_one_by_email'
            };

            client.query(queryConfig, function (err, queryResult) {

                if (err) {
                    console.error(err);
                    done(err);
                    return callback(err);
                }

                done();

                if (queryResult.rowCount === 0) {
                    return callback(Boom.unauthorized(c.USER_NOT_FOUND, 'basic'));
                }

                callback(null, queryResult.rows[0]);
            });
        },
        function (user, callback) {

            Bcrypt.compare(password, user.password, function (err, isValid) {

                if (err) {
                    return callback(Boom.unauthorized(err, 'basic'));
                }

                user.password = password;
                callback(null, isValid, user);
            });
        }
    ], function (err, isValid, user) {

        if (err || !isValid) {
            return finish(err, false);
        }

        finish(err, isValid, user);
    });
};


var validateToken = function (token, callback) {

    Token.validateBearerToken(token, function (err, userInfo) {
        if (err) {
            return callback(Boom.unauthorized(c.TOKEN_INVALID, 'token'), false, null);
        }

        callback(null, true, userInfo);
    });
};


exports.register = function (server, options, next) {

    server.auth.strategy('simple', 'basic', {
        validateFunc: validateSimple
    });

    server.auth.strategy('token', 'bearer-access-token', {
        validateFunc: validateToken
    });

    next();
};


exports.register.attributes = {
    name: 'authenticate'
};
