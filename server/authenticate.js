var Async = require('async');
var Bcrypt = require('bcrypt');
var Boom = require('boom');
var Cache = require('./cache');
var Config = require('../config');
var Pg = require('pg').native;
var c = require('./constants');

var exports = module.exports = {};

var validateSimple = function (email, password, finish) {

    Async.waterfall([
        function (callback) {

            var db = Config.get('/db/connectionString');
            Pg.connect(db, function (err, client, done) {

                return callback(err, client, done);
            });
        },
        function (client, done, callback) {

            var queryConfig = {
                text: 'SELECT id, name, password, email FROM person WHERE email = $1 AND deleted = false',
                values: [email],
                name: 'person_by_email'
            };

            client.query(queryConfig, function (err, queryResult) {

                if (err) {
                    console.error(err);
                    done(err);
                    return callback(err);
                }

                done();

                if (queryResult.rowCount === 0) {
                    return callback(Boom.unauthorized(c.PERSON_NOT_FOUND, 'basic'));
                }

                return callback(null, queryResult.rows[0]);
            });
        },
        function (person, callback) {

            Bcrypt.compare(password, person.password, function (err, isValid) {

                if (err) {
                    return callback(Boom.unauthorized(err, 'basic'));
                }

                person.password = password;
                return callback(null, isValid, person);
            });
        }
    ], function (err, isValid, person) {

        if (err || !isValid) {
            return finish(err, false);
        }

        return finish(err, isValid, person);
    });
};


var validateToken = function (token, callback) {

    Cache.validateToken(token, function (err, personInfo) {
        if (err) {
            return callback(Boom.unauthorized(c.AUTH_TOKEN_INVALID, 'token'), false, null);
        }

        return callback(null, true, personInfo);
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
