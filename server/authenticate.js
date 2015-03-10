var Async = require('async');
var Bcrypt = require('bcrypt');
var Config = require('../config');
var Pg = require('pg').native;
var c = require('./constants');

var validate = function (email, password, finish) {

    Async.waterfall([
        function (callback) {

            var db = Config.get('/db/connectionString');
            Pg.connect(db, function (connectErr, client, done) {

                callback(connectErr, client, done);
            });
        },
        function (client, done, callback) {

            var queryConfig = {
                text: 'SELECT id, username, password FROM users WHERE email = $1',
                values: [email],
                name: 'users_select_one_by_email'
            };
            
            client.query(queryConfig, function (queryErr, queryResult) {

                done();

                if (queryErr) {
                    callback(queryErr);
                }
                else if (queryResult.rowCount === 0) {
                    callback({message: c.UserNotFound});
                }
                else {
                    callback(null, queryResult.rows[0]);
                }
            });
        },
        function (user, callback) {

            Bcrypt.compare(password, user.password, function (err, isValid) {
                callback(err, isValid, user);
            });
        }
    ], function (err, isValid, user) {

        if (err) {
            console.error(err);
            return finish(err, false);
        }

        console.info(user);
        finish(err, isValid, { id: user.id, name: user.name });
    });
};


exports.register = function (server, options, next) {

    server.auth.strategy('simple', 'basic', {
        validateFunc: validate
    });

    next();
};


exports.register.attributes = {
    name: 'authenticate'
};
