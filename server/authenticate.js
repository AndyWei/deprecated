var Bcrypt = require('bcrypt');
var Basic = require('hapi-auth-basic');
var c = require('./constants');

exports.register = function (server, options, next) {

    server.auth.strategy('simple', 'basic', {
        validateFunc: function (username, password, callback) {

            var queryConfig = {
                text: 'SELECT id, password FROM users WHERE username = $1 LIMIT 1',
                values: [username]
            };

            request.pg.client.query(queryConfig, function (err, result) {

                if (err) {
                    return callback(err, false);
                }

                if (result.rows.length === 0) {
                    return callback(null, false);
                }

                Bcrypt.compare(password, result.rows[0].password, function (err, isValid) {

                    callback(err, isValid, { id: user.id, name: username });
                });
            });
        }
    });

    next();
}


exports.register.attributes = {
    name: 'authenticate'
};
