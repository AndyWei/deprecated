var Async = require('async');
var Bcrypt = require('bcrypt');
var Boom = require('boom');
var Cache = require('../cache');
var Hoek = require('hoek');
var Joi = require('joi');
var Rand = require('rand-token');
var c = require('../constants');


var internals = {};

exports.register = function (server, options, next) {

    options = Hoek.applyToDefaults({ basePath: '' }, options);

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

            internals.generateAuthToken(request.auth.credentials.id, request.auth.credentials.name, function (err, token) {

                if (err) {
                    console.error(err);
                    request.pg.kill = true;
                    return reply(err);
                }

                var response = request.auth.credentials;
                response.token = token;

                reply(null, response);
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
                    password: Joi.string().min(4).max(30).required()
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
    name: 'sign'
};


internals.emailCheck = function (request, reply) {

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
            return reply(Boom.conflict(c.EMAIL_IN_USE));
        }

        reply(true);
    });
};


internals.createUser = function (request, reply) {

    var email = request.payload.email;
    var name = email.substring(0, 3); // auto given name is the first 3 chars of email

    Async.auto({
        salt: function (callback) {

            Bcrypt.genSalt(c.BCRYPT_ROUND, function(err, salt) {
                callback(err, salt);
            });
        },
        password: ['salt', function (callback, results) {

            Bcrypt.hash(request.payload.password, results.salt, function(err, hash) {
                 callback(err, hash);
            });
        }],
        personId: ['password', function (callback, results) {

            var org = internals.getOrgFromEmail(email);
            var queryConfig = {
                text: 'INSERT INTO person ' +
                          '(email, name, password, org_name, org_type, created_at, updated_at) VALUES ' +
                          '($1, $2, $3, $4, $5, now(), now()) ' +
                          'RETURNING id',
                values: [email, name, results.password, org.name, org.type],
                name: 'person_create'
            };

            request.pg.client.query(queryConfig, function (err, queryResult) {
                if (err) {
                    request.pg.kill = true;
                    return callback(err);
                }

                if (queryResult.rowCount === 0) {
                    return callback(Boom.badImplementation(c.USER_CREATE_FAILED));
                }

                callback(err, queryResult.rows[0].id);
            });
        }],
        token: ['personId', function (callback, results) {

            internals.generateAuthToken(results.personId, name, function (err, token) {
                callback(err, token);
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
                token: results.token
        };

        console.log('user created. email=%s, name = %s', email, name);
        reply(null, message).code(201);
    });
};

internals.getOrgFromEmail = function (email) {

    // email = john.smith@apple.com.cn
    var domain = email.substring(email.lastIndexOf('@') + 1); // apple.com.cn
    var fields = domain.split('.');                           // [apple, com, cn]
    var orgType;
    switch (fields[1]) {
        case 'com':
            orgType = c.OrgType.COM;
            break;
        case 'edu':
            orgType = c.OrgType.EDU;
            break;
        case 'org':
            orgType = c.OrgType.ORG;
            break;
        default:
            orgType = c.OrgType.OTHER;
    }

    var org = {
        name: fields[0],
        type: orgType
    };
    return org;
};


// Generate a 20 character alpha-numeric token and store it in cache together with personId
internals.generateAuthToken = function (personId, name, callback) {

    personId = personId.toString();
    name = name.toString();

    Async.auto({
        token: function (next) {

            var randomString = Rand.generate(c.TOKEN_LENGTH);
            return next(null, randomString);
        },
        userToken: ['token', function (next, result) {

            var personInfo = result.token + ':' + name;
            var userToken = personId + ':' + result.token;

            Cache.setex(c.AUTH_TOKEN_CACHE, personId, personInfo, function (err) {

                if (err) {
                    return next(err);
                }

                return next(null, userToken);
            });
        }]
    }, function (err, result) {

        if (err) {
            console.error(err);
            return callback(err);
        }

        return callback(null, result.userToken);
    });
};
