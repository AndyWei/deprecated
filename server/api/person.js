var Async = require('async');
var Boom = require('boom');
var Cache = require('../cache');
var Hoek = require('hoek');
var Joi = require('joi');
var c = require('../constants');

var internals = {};

var selectClause = 'SELECT id, name, org_name, org_type, gender, yob, bio, url, updated_at, \
                    ST_X(coordinate) AS lon, ST_Y(coordinate) AS lat \
                    FROM person ';

var selectProfileClause = 'SELECT id, email, name, role, org_name, org_type, gender, yob, bio, url, validated, member_expire_at FROM person ';

exports.register = function (server, options, next) {

    options = Hoek.applyToDefaults({ basePath: '' }, options);

    // get a person record by id. auth.
    server.route({
        method: 'GET',
        path: options.basePath + '/person',
        config: {
            auth: {
                strategy: 'token'
            },
            validate: {
                query: {
                    id: Joi.string().regex(/^[0-9]+$/).max(19).required()
                }
            }
        },
        handler: function (request, reply) {

            var queryConfig = {
                name: 'person_by_id',
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

                return reply(null, result.rows);
            });
        }
    });


    // get all the validated people nearby a point. auth.
    server.route({
        method: 'GET',
        path: options.basePath + '/person/nearby',
        config: {
            auth: {
                strategy: 'token'
            },
            validate: {
                query: {
                    lon: Joi.number().min(-180).max(180).required(),
                    lat: Joi.number().min(-90).max(90).required(),
                    distance: Joi.number().min(1).max(1000).default(2),  // in kilometers
                    after: Joi.string().regex(/^[0-9]+$/).max(19).default('0'),
                    before: Joi.string().regex(/^[0-9]+$/).max(19).default('9223372036854775807')
                }
            }
        },
        handler: function (request, reply) {

            var q = request.query;
            var degree = internals.degreeFromDistance(q.distance);

            var where = 'WHERE id > $1 AND id < $2 AND ST_DWithin(coordinate, ST_SetSRID(ST_MakePoint($3, $4), 4326), $5) AND validated = true AND deleted = false ';
            var order = 'ORDER BY id DESC ';
            var limit = 'LIMIT 10';

            var queryValues = [q.after, q.before, q.lon, q.lat, degree];
            var queryConfig = {
                name: 'person_nearby',
                text: selectClause + where + order + limit,
                values: queryValues
            };

            request.pg.client.query(queryConfig, function (err, result) {

                if (err) {
                    console.error(err);
                    request.pg.kill = true;
                    return reply(err);
                }

                return reply(null, result.rows);
            });
        }
    });


    // get a person's own profile. auth.
    server.route({
        method: 'GET',
        path: options.basePath + '/person/profile',
        config: {
            auth: {
                strategy: 'token'
            }
        },
        handler: function (request, reply) {

            var queryConfig = {
                name: 'person_profile',
                text: selectProfileClause +
                      'WHERE id = $1 AND deleted = false',
                values: [request.auth.credentials.id]
            };

            request.pg.client.query(queryConfig, function (err, result) {

                if (err) {
                    console.error(err);
                    request.pg.kill = true;
                    return reply(err);
                }

                return reply(null, result.rows);
            });
        }
    });


    // update an person profile. auth.
    server.route({
        method: 'POST',
        path: options.basePath + '/person/profile',
        config: {
            auth: {
                strategy: 'token'
            },
            validate: {
                payload: {
                    name: Joi.string().max(30).required(),
                    gender: Joi.number().min(0).max(3).required().default(0),
                    yob: Joi.number().min(1900).max(2010).required().default(0),
                    bio: Joi.string().max(2000).required().default('.')
                }
            }
        },
        handler: function (request, reply) {

            var p = request.payload;
            var personId = request.auth.credentials.id;

            Async.waterfall([

                function (callback) {

                    var queryConfig = {
                        name: 'person_update_profile',
                        text: 'UPDATE person SET name = $1, gender = $2, yob = $3, bio = $4, updated_at = now() ' +
                              'WHERE id = $5 AND deleted = false ' +
                              'RETURNING id',
                        values: [p.name, p.gender, p.yob, p.bio, personId]
                    };

                    request.pg.client.query(queryConfig, function (err, result) {

                        if (err) {
                            request.pg.kill = true;
                            return callback(err);
                        }

                        if (result.rows.length === 0) {
                            return callback(Boom.badRequest(c.PERSON_UPDATE_FAILED));
                        }

                        return callback(null);
                    });
                },
                function (callback) {

                    internals.updateCachedName(personId.toString(), p.name, function (err) {
                        if (err) {
                            console.error(err); // Do not callback(err) since the cached name will be corrected in next sign in
                        }
                        return callback(null);
                    });
                }
            ], function (err) {

                if (err) {
                    console.error(err);
                    return reply(err);
                }

                return reply(null, { id: personId });
            });
        }
    });


    // update an person's coordinate. auth.
    server.route({
        method: 'POST',
        path: options.basePath + '/person/coordinate',
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
            var personId = request.auth.credentials.id;

            var queryConfig = {
                name: 'person_update_coordinate',
                text: 'UPDATE person SET coordinate = ST_SetSRID(ST_MakePoint($1, $2), 4326), updated_at = now() ' +
                      'WHERE id = $3 AND deleted = false ' +
                      'RETURNING id',
                values: [p.lon, p.lat, personId]
            };

            request.pg.client.query(queryConfig, function (err, result) {

                if (err) {
                    console.error(err);
                    request.pg.kill = true;
                    return reply(err);
                }

                if (result.rows.length === 0) {
                    return reply(Boom.badRequest(c.PERSON_UPDATE_FAILED));
                }

                return reply(null, result.rows[0]);
            });
        }
    });

    next();
};


internals.updateCachedName = function (personId, name, callback) {

    personId = personId.toString();

    Async.waterfall([

        function (next) {
            Cache.get(c.AUTH_TOKEN_CACHE, personId, function (err, result) {

                if (err) {
                    return next(err);
                }

                if (!result) {
                    return next(null, null);
                }

                var token = result.substring(result.indexOf(':') + 1);
                return next(null, token);
            });
        },
        function (token, next) {

            var authInfo = token + ':' + name;
            Cache.setex(c.AUTH_TOKEN_CACHE, personId, authInfo, function (err) {

                if (err) {
                    return next(err);
                }

                return next(null);
            });
        }
    ], function (err) {

        if (err) {
            console.error(err);
            return callback(err);
        }

        return callback(null);
    });
};


/*
 *  convert distance in km to GPS degree
 */
internals.degreeFromDistance = function(distance) {

    return distance * c.DEGREE_FACTOR;
};

exports.register.attributes = {
    name: 'person'
};
