var Boom = require('boom');
var Hoek = require('hoek');
var Joi = require('joi');
var c = require('../constants');

var internals = {};

var selectClause = 'SELECT id, gender, rating, rating_count, invite_count, \
                    display_name, age, bio, portrait_url, hourly_rate, created_at, updated_at, \
                    ST_X(coordinate) AS lon, ST_Y(coordinate) AS lat \
                    FROM jyuser ';

exports.register = function (server, options, next) {

    options = Hoek.applyToDefaults({ basePath: '' }, options);

    // get a user by id. no auth.
    server.route({
        method: 'GET',
        path: options.basePath + '/user',
        config: {
            validate: {
                query: {
                    id: Joi.string().regex(/^[0-9]+$/).max(19)
                }
            }
        },
        handler: function (request, reply) {

            var queryConfig = {
                name: 'user_by_id',
                text: selectClause +
                      'WHERE id = $1 AND deleted = false',
                values: [request.query.id]
            };

            request.pg.client.query(queryConfig, function (err, result) {

                if (err) {
                    console.error(err);
                    request.pg.kill = true;
                    return reply(err);
                }

                if (result.rows.length === 0) {
                    return reply(Boom.notFound(c.RECORD_NOT_FOUND));
                }

                reply(null, result.rows[0]);
            });
        }
    });


    // get a user's own information. auth.
    server.route({
        method: 'GET',
        path: options.basePath + '/user/me',
        config: {
            auth: {
                strategy: 'token'
            }
        },
        handler: function (request, reply) {

            var queryConfig = {
                name: 'user_me',
                text: 'SELECT * FROM jyuser ' +
                      'WHERE id = $1 AND deleted = false',
                values: [request.auth.credentials.id]
            };

            request.pg.client.query(queryConfig, function (err, result) {

                if (err) {
                    console.error(err);
                    request.pg.kill = true;
                    return reply(err);
                }

                if (result.rows.length === 0) {
                    return reply(Boom.notFound(c.RECORD_NOT_FOUND));
                }

                reply(null, result.rows[0]);
            });
        }
    });


    // get all the user nearby a point. no auth.
    server.route({
        method: 'GET',
        path: options.basePath + '/user/nearby',
        config: {
            validate: {
                query: {
                    lon: Joi.number().min(-180).max(180).required(),
                    lat: Joi.number().min(-90).max(90).required(),
                    distance: Joi.number().min(1).max(1000).default(2),  // in kilometers
                    category: Joi.number().min(1).max(4).required(),      // the service category
                    rating_below: Joi.number().min(0).max(5000).default(5000)
                }
            }
        },
        handler: function (request, reply) {

            var q = request.query;
            var degree = internals.degreeFromDistance(q.distance);

            var where = 'WHERE rating <= $1 AND category = $2 AND joyyor_status < 100 AND ST_DWithin(coordinate, ST_SetSRID(ST_MakePoint($3, $4), 4326), $5) AND deleted = false ';
            var order = 'ORDER BY rating DESC ';
            var limit = 'LIMIT 25';

            var queryValues = [q.rating_below, q.category, q.lon, q.lat, degree];
            var queryConfig = {
                name: 'user_nearby',
                text: selectClause + where + order + limit,
                values: queryValues
            };

            request.pg.client.query(queryConfig, function (err, result) {

                if (err) {
                    console.error(err);
                    request.pg.kill = true;
                    return reply(err);
                }

                reply(null, result.rows);
            });
        }
    });


    // update an user profile. auth.
    server.route({
        method: 'POST',
        path: options.basePath + '/user/profile',
        config: {
            auth: {
                strategy: 'token'
            },
            validate: {
                payload: {
                    age: Joi.number().min(16).max(100).required(),
                    bio: Joi.string().max(1000).required(),
                    category: Joi.number().min(0).max(4).required(),
                    country: Joi.string().length(2).regex(/^[a-z]+$/).default('us'),
                    currency: Joi.string().length(3).regex(/^[a-z]+$/).default('usd'),
                    display_name: Joi.string().max(20).required(),
                    gender: Joi.string().regex(/^[a-z]+$/).length(1).required(),
                    hourly_rate: Joi.number().min(0).max(1000000).required()
                }
            }
        },
        handler: function (request, reply) {

            var p = request.payload;
            var u = request.auth.credentials;

            var queryConfig = {
                name: 'user_profile',
                text: 'UPDATE jyuser SET age = $1, bio = $2, category = $3, country = $4, currency = $5, display_name = $6, gender = $7, hourly_rate = $8, updated_at = now() ' +
                      'WHERE id = $9 AND deleted = false ' +
                      'RETURNING id',
                values: [p.age, p.bio, p.category, p.country, p.currency, p.display_name, p.gender, p.hourly_rate, u.id]
            };

            request.pg.client.query(queryConfig, function (err, result) {

                if (err) {
                    console.error(err);
                    request.pg.kill = true;
                    return reply(err);
                }

                if (result.rows.length === 0) {
                    return reply(Boom.badRequest(c.USER_UPDATE_FAILED));
                }

                reply(null, result.rows[0]);
            });
        }
    });


    // update an user's coordinate. auth.
    server.route({
        method: 'POST',
        path: options.basePath + '/user/coordinate',
        config: {
            auth: {
                strategy: 'token'
            },
            validate: {
                payload: {
                    lon: Joi.number().min(-180).max(180).required(),
                    lat: Joi.number().min(-90).max(90).required()
                }
            }
        },
        handler: function (request, reply) {

            var p = request.payload;
            var u = request.auth.credentials;

            var queryConfig = {
                name: 'user_coordinate',
                text: 'UPDATE jyuser SET coordinate = ST_SetSRID(ST_MakePoint($1, $2), 4326), updated_at = now() ' +
                      'WHERE id = $3 AND deleted = false ' +
                      'RETURNING id',
                values: [p.lon, p.lat, u.id]
            };

            request.pg.client.query(queryConfig, function (err, result) {

                if (err) {
                    console.error(err);
                    request.pg.kill = true;
                    return reply(err);
                }

                if (result.rows.length === 0) {
                    return reply(Boom.badRequest(c.USER_UPDATE_FAILED));
                }

                reply(null, result.rows[0]);
            });
        }
    });

    next();
};


/*
 *  convert distance in km to GPS degree
 */
internals.degreeFromDistance = function(distance) {

    return distance * c.DEGREE_FACTOR;
};

exports.register.attributes = {
    name: 'user'
};
