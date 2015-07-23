var Async = require('async');
var Boom = require('boom');
var Cache = require('../cache');
var Const = require('../constants');
var Hoek = require('hoek');
var Joi = require('joi');
var Utils = require('../utils');
var _ = require('underscore');


var internals = {};

var selectClause = 'SELECT id, name, org_name, org_type, gender, yob, bio, url, heart_count, friend_count, updated_at FROM person ';

var selectProfileClause = 'SELECT id, email, name, role, org_name, org_type, gender, yob, bio, url, heart_count, friend_count, validated, member_expire_at FROM person ';

exports.register = function (server, options, next) {

    options = Hoek.applyToDefaults({ basePath: '' }, options);

    // get person records by ids. auth.
    server.route({
        method: 'GET',
        path: options.basePath + '/person',
        config: {
            auth: {
                strategy: 'token'
            },
            validate: {
                query: {
                    id: Joi.array().single(true).unique().items(Joi.string().regex(/^[0-9]+$/).max(19))
                }
            }
        },
        handler: function (request, reply) {

            var personIds = request.query.id;
            var parameterList = Utils.parametersString(1, personIds.length);
            var queryConfig = {
                // Warning: DO NOT give a name to this query since it has variable parameters
                text: selectClause +
                      'WHERE id in ' + parameterList + ' AND deleted = false',
                values: personIds
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
                    before: Joi.string().regex(/^[0-9]+$/).max(19).default(Const.MAX_ID)
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
                        text: 'UPDATE person SET name = $1, gender = $2, yob = $3, bio = $4, updated_at = $5 ' +
                              'WHERE id = $6 AND deleted = false ' +
                              'RETURNING id',
                        values: [p.name, p.gender, p.yob, p.bio, _.now(), personId]
                    };

                    request.pg.client.query(queryConfig, function (err, result) {

                        if (err) {
                            request.pg.kill = true;
                            return callback(err);
                        }

                        if (result.rows.length === 0) {
                            return callback(Boom.badRequest(Const.PERSON_UPDATE_PROFILE_FAILED));
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


    // update an person's location. auth.
    server.route({
        method: 'POST',
        path: options.basePath + '/person/location',
        config: {
            auth: {
                strategy: 'token'
            },
            validate: {
                payload: {
                    lon: Joi.number().min(-180).max(180).required(),
                    lat: Joi.number().min(-90).max(90).required(),
                    cell_id: Joi.string().max(12).required()
                }
            }
        },
        handler: function (request, reply) {

            var p = request.payload;
            var personId = request.auth.credentials.id;

            Async.waterfall([

                function (callback) {
                    var queryConfig = {
                        name: 'person_update_location',
                        text: 'UPDATE person SET cell_id = $1, coordinate = ST_SetSRID(ST_MakePoint($2, $3), 4326), updated_at = $4 ' +
                              'WHERE id = $5 AND deleted = false ' +
                              'RETURNING id, heart_count, friend_count',
                        values: [p.cell_id, p.lon, p.lat, _.now(), personId]
                    };

                    request.pg.client.query(queryConfig, function (err, result) {

                        if (err) {
                            console.error(err);
                            request.pg.kill = true;
                            return callback(err);
                        }

                        if (result.rows.length === 0) {
                            return callback(Boom.badRequest(Const.PERSON_UPDATE_LOCATION_FAILED));
                        }

                        return callback(null, result.rows[0]);
                    });
                },
                function (person, callback) {

                    var score = (person.heart_count * 5) + (person.friend_count * 10);
                    Cache.updateSortedSet(Const.PERSON_CACHE, p.cell_id, score, personId.toString(), function (err) {
                        if (err) {
                            return callback(err);
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

    next();
};


internals.updateCachedName = function (personId, name, callback) {

    personId = personId.toString();

    Async.waterfall([

        function (next) {
            Cache.get(Const.AUTH_TOKEN_CACHE, personId, function (err, result) {

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
            Cache.setex(Const.AUTH_TOKEN_CACHE, personId, authInfo, function (err) {

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

    return distance * Const.DEGREE_FACTOR;
};

exports.register.attributes = {
    name: 'person'
};
