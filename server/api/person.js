var Async = require('async');
var Boom = require('boom');
var Cache = require('../cache');
var Const = require('../constants');
var Hoek = require('hoek');
var Joi = require('joi');
var Utils = require('../utils');
var _ = require('underscore');

var internals = {};
var selectClause = 'SELECT id, name, org, orgtype, gender, yob, bio, url, hearts, friends, ut FROM person ';
var selectProfileClause = 'SELECT id, email, name, role, org, orgtype, gender, yob, bio, url, hearts, friends, verified, met FROM person ';


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


    // get all the verified people nearby a point. auth.
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

            var where = 'WHERE id > $1 AND id < $2 AND ST_DWithin(coords, ST_SetSRID(ST_MakePoint($3, $4), 4326), $5) AND verified = true AND deleted = false ';
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


    // update a person's device information
    server.route({
        method: 'POST',
        path: options.basePath + '/person/device',
        config: {
            auth: {
                strategy: 'token'
            },
            validate: {
                payload: {
                    service: Joi.number().min(0).max(2).required(),
                    device: Joi.string().max(100).required(),
                    badge: Joi.number().min(0).max(1000).default(0)
                }
            }
        },
        handler: function (request, reply) {

            var personId = request.auth.credentials.id;
            var personObj = {
                service: request.payload.service,
                device: request.payload.device,
                badge: request.payload.badge
            };

            Cache.hmset(Const.PERSON_HASHES, personId, personObj, function (err) {

                if (err) {
                    console.error(err);
                    return reply(err);
                }

                console.log('Received device token %s for personId %s', request.payload.token, personId);
                reply(null, {id: personId});
            });
        }
    });


    // update a person's profile. auth.
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
                        text: 'UPDATE person SET name = $1, gender = $2, yob = $3, bio = $4, ut = $5 ' +
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

                    Cache.hset(Const.PERSON_HASHES, personId, 'name', p.name, function (err) {
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
                    cell: Joi.string().max(12).required()
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
                        text: 'UPDATE person SET cell = $1, coords = ST_SetSRID(ST_MakePoint($2, $3), 4326), ut = $4 ' +
                              'WHERE id = $5 AND deleted = false ' +
                              'RETURNING id, hearts, friends',
                        values: [p.cell, p.lon, p.lat, _.now(), personId]
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

                    var score = (person.hearts * 5) + (person.friends * 10);
                    Cache.zadd(Const.CELL_PERSON_SETS, p.cell, score, personId, function (err) {
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


/*
 *  convert distance in km to GPS degree
 */
internals.degreeFromDistance = function(distance) {

    return distance * Const.DEGREE_FACTOR;
};

exports.register.attributes = {
    name: 'person'
};
