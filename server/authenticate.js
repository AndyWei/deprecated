var Async = require('async');
var Bcrypt = require('bcrypt');
var Boom = require('boom');
var Config = require('../config');
var Pg = require('pg').native;
var TokenManager = require('./tokenmanager');
var c = require('./constants');

var validateSimple = function (username, password, finish) {

    Async.waterfall([
        function (callback) {

            var db = Config.get('/db/connectionString');
            Pg.connect(db, function (connectErr, client, done) {

                callback(connectErr, client, done);
            });
        },
        function (client, done, callback) {

            var queryConfig = {
                text: 'SELECT id, password FROM users WHERE username = $1',
                values: [username],
                name: 'users_select_one_by_username'
            };

            client.query(queryConfig, function (queryErr, queryResult) {

                done();

                if (queryErr) {
                    console.error(c.QUERY_FAILED, queryErr);
                    callback(Boom.badImplementation(c.QUERY_FAILED, queryErr));
                }
                else if (queryResult.rowCount === 0) {
                    callback(Boom.unauthorized(c.USER_NOT_FOUND, 'basic'));
                }
                else {
                    callback(null, queryResult.rows[0]);
                }
            });
        },
        function (user, callback) {

            Bcrypt.compare(password, user.password, function (err, isValid) {
                if (err) {
                    callback(Boom.unauthorized(err, 'basic'));
                }
                else {
                    callback(null, isValid, user);
                }
            });
        }
    ], function (err, isValid, user) {

        if (err || !isValid) {
            return finish(err, false);
        }

        finish(err, isValid, { id: user.id, username: username });
    });
};


var validateToken = function (token, callback) {

    // var userCredentials = {
    //     id: 1
    // };
    // // Use a real strategy here to check if the token is valid
    // if (token === '123456789') {
    //     callback(null, true, userCredentials);
    // } else {
    //     callback(Boom.unauthorized(c.TOKEN_INVALID, 'token'), false, null);
    // }

    TokenManager.validate(token, function (err, uid) {
        if (err) {
            return callback(Boom.unauthorized(c.TOKEN_INVALID, 'token'), false, null);
        }

        var userCredentials = {
            id: uid
        };

        callback(null, true, userCredentials);
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
