var Async = require('async');
var Bcrypt = require('bcrypt');
var Hoek = require('hoek');
var Joi = require('joi');
var c = require('../constants');
var _ = require('underscore');


// Declare internals
var internals = {};

exports.register = function (server, options, next) {

    options = Hoek.applyToDefaults({ basePath: '' }, options);

    // new user signup
    server.route({
        method: 'POST',
        path: options.basePath + '/signup',
        config: {
            validate: {
                payload: {
                    email: Joi.string().email().lowercase().min(3).max(30).required(),
                    password: Joi.string().min(6).max(30).required()
                }
            },
            pre: [{
                assign: 'emailCheck',
                method: internals.emailCheck
            }]
        },
        handler: internals.createUser
    });

    next();
};


exports.register.attributes = {
    name: 'signup'
};


internals.emailCheck = function (request, reply) {

    console.info('emailCheck');

    var queryConfig = {
        text: 'SELECT id FROM users WHERE email = $1',
        values: [request.payload.email]
    };

    request.pg.client.query(queryConfig, function (err, result) {

        if (err) {
            return reply(err);
        }

        if (result.rows.length > 0) {
            var response = {
                message: c.UserExists
            };

            return reply(response).takeover().code(409);
        }

        reply(true);
    });
};


// Before create user we need to generate a username from the user's email address
// Since the username will be visible for other users in non-anonymous scenarios, below requirem should be followed:
//   1. Security: there should be no one can conduct the user's email address from the generated username, so michael@gmail.com should not map to "michael"
//   2. User-friendly: if the user has already implied his/her name, use it. E.g., frank.underwood@whitehouse.com -> "frank"
//   3. Unique: In case the best name from step 1 and 2 has already been taken, some random numbers will be appended
internals.createUser = function (request, reply) {

    console.info('createUser');
    var email = request.payload.email;

    Async.auto({
        usernameCandidates: function (callback) {

            var candidates = internals.getUsernameCandidates(email);
            console.info('usernameCandidates = %j', candidates);
            callback(null, candidates);
        },
        usernameAvailable: ['usernameCandidates', function (callback, results) {

            var available = results.usernameCandidates;
            var query = request.pg.client.query({
                text: 'SELECT username FROM users WHERE username IN ($1, $2, $3, $4, $5)',
                values: results.usernameCandidates
            });

            query.on('row', function (row) {

                console.info('row');
                available = _.without(available, row.username);
                console.info('available = %j', available);
            });

            query.on('error', function(err) {
                callback(err);
            });

            query.on('end', function() {
                callback(null, available);
            });
        }],
        username: ['usernameAvailable', function (callback, results) {

            var name = null;
            if (results.usernameAvailable.length === 0) {
                // generate a base36 name from timestamp + random5
                name = internals.base36(_.now()) + internals.base36(_.random(10000, 99999));
                console.info('base36 username = %s', name);
            }
            else {
                // choose the shortest name
                name = _.min(results.usernameAvailable, function(iteratee) {
                    return iteratee.length;
                });
            }

            callback(null, name);
        }],
        salt: function (callback) {

            Bcrypt.genSalt(10, function(err, salt) {
                callback(err, salt);
            });
        },
        password: ['salt', function (callback, results) {

            Bcrypt.hash(request.payload.password, results.salt, function(err, hash) {
                 callback(err, hash);
            });
        }],
        create: ['username', 'password', function (callback, results) {

            var queryConfig = {
                text: 'INSERT INTO users' +
                          '(username, password, email, role, created_at, updated_at) VALUES' +
                          '($1, $2, $3, $4, now(), now())',
                values: [results.username, results.password, email, c.Role.user.value]
            };

            request.pg.client.query(queryConfig, function (err, queryResult) {
                callback(err, queryResult);
            });
        }]
    }, function (err, results) {

        if (err) {
            console.info('err');
            return reply(err);
        }

        var message = {
            user: {
                username: results.username,
                email: email
            }
        };

        console.info('user created');
        reply(null, message).code(201);
    });
};


internals.getUsernameCandidates = function (email) {

    var original = email.split('@')[0];
    var purename = original.replace('.', '');
    var firstname = original.split(/[\d._'-]/)[0];

    // gmail ignores '.', so spams can conduct the user's gmail address from the pure name too
    if (firstname === original ||
        firstname === purename) {

        var end = _.min([firstname.length, c.ALPHA_LENGTH]);
        firstname = purename.slice(0, end);
    }

    // in case someone's email is like ________@gmail.com or 20150209@gmal.com
    if (firstname.length === 0) {
        firstname = internals.base36(_.now());
    }

    var firstname1 = firstname + _.random(1, 9).toString();
    var firstname2 = firstname + _.random(10, 99).toString();
    var firstname3 = firstname + _.random(100, 999).toString();
    var firstname4 = firstname + _.random(1000, 9999).toString();

    return [firstname, firstname1, firstname2, firstname3, firstname4];
};


internals.base36 = function (num) {
    if (num !== null &&
        num !== undefined) {      // Explicit check as 'num' can be 0

        return num.toString(36);
    }
    return 'undefined_num';
};
