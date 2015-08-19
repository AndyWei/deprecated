var Async = require('async');
var Boom = require('boom');
var Cache = require('../cache');
var Const = require('../constants');
var Hoek = require('hoek');
var Joi = require('joi');
var Utils = require('../utils');
var _ = require('lodash');

var internals = {};
var selectInfo = 'SELECT id, name, org, orgtype, gender, yob, bio, ppf, hearts, score, ut FROM person ';
var selectOwn = 'SELECT id, email, name, role, org, orgtype, gender, yob, bio, ppf, hearts, friends, score, verified, met FROM person ';


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
                    cell: Joi.string().max(12).required(),
                    id: Joi.array().single(true).unique().max(Const.PERSON_PER_QUERY).items(Joi.string().regex(/^[0-9]+$/).max(19))
                }
            }
        },
        handler: function (request, reply) {

            var q = request.query;
            var personIds = q.id;

            Async.waterfall([
                function (callback) {

                    Cache.mhgetall(Const.PERSON_HASHES, personIds, function (err, result) {
                        if (err) {
                            console.error(err);
                        }

                        // result is an array, and each element is an array in form of [err, personObj]
                        var foundObjs = _(result).map(_.last).compact().reject(_.isEmpty).value();
                        var foundIds = _.pluck(foundObjs, 'id');
                        var missedIds = _.difference(personIds, foundIds);

                        return callback(null, missedIds, foundObjs);
                    });
                },
                function (missedIds, cachedObjs, callback) {
                    if (_.isEmpty(missedIds)) {
                        return callback(null, cachedObjs);
                    }

                    internals.searchPersonByIdsFromDB(request, missedIds, function (err, result) {

                        // write missed records back to cache
                        // NOTE: we cannot use missedIds here since the sequence of records in result are different
                        var ids = _.pluck(result, 'id');
                        var objs = _.map(result, function (obj) {
                            // remove all falsy properties to save cache space
                            // see http://stackoverflow.com/questions/14058193/remove-empty-properties-falsy-values-from-object-with-underscore-js
                            return _.pick(obj, _.identity);
                        });
                        Cache.mhmset(Const.PERSON_HASHES, ids, objs);

                        // aggregate objs from cache and DB
                        var mergedObjs = cachedObjs.concat(objs);
                        var sortedObjs = _.sortBy(mergedObjs, function (person) {
                            return person.score * -1;  // Sort objs in DESC order by score
                        });

                        return callback(null, sortedObjs);
                    });
                }
            ], function (err, results) {

                if (err) {
                    console.error(err);
                    return reply(err);
                }

                return reply(null, results);
            });
        }
    });


    // get person id list in the cell. auth.
    // Each cell has a sorted person id set read-through cache, and the key is the person score
    // In case of cache missing, DB will be queried and return a list of (personId, score) and update cache
    server.route({
        method: 'GET',
        path: options.basePath + '/person/nearby',
        config: {
            auth: {
                strategy: 'token'
            },
            validate: {
                query: {
                    cell: Joi.string().max(12).required(),
                    min: Joi.number().integer().default(0), // the minimum score, the search will include this value
                    max: Joi.number().positive().integer().default(Const.MAX_SCORE) // the maximum score, the search will include this value
                }
            }
        },
        handler: function (request, reply) {

            var q = request.query;
            Async.waterfall([
                function (callback) {
                    Cache.zcard(Const.CELL_PERSON_SETS, q.cell, function (err, result) {
                        if (err) {
                            console.error(err);
                            return callback(null, 0); // continue search in DB
                        }

                        return callback(null, result);
                    });
                },
                function (setSize, callback) {
                    if (setSize === 0) {
                         return callback(null, 0, null);
                    }

                    Cache.zrevrangebyscore(Const.CELL_PERSON_SETS, q.cell, q.max, q.min, Const.PERSON_PER_QUERY, function (err, result) {
                        if (err) {
                            console.error(err);
                            return callback(null, 0, null); // continue search in DB
                        }

                        if (result.length === 0) {                          // found nothing in cache
                            if (q.min !== 0 && q.max === Const.MAX_SCORE) { // client wants higher score ones
                                return callback(null, setSize, []);         // just return empty result
                            }
                            else {                                          // client wants lower score ones
                                return callback(null, 0, null);             // search in DB
                            }
                        }

                        return callback(null, setSize, result);
                    });
                },
                function (setSize, personIds, callback) {
                    if (setSize === 0) {
                        internals.searchPersonIdByCellFromDB(request, function (err, result) {

                            if (result.length === 0) {
                                return callback(null, []);
                            }

                            var ids = _.pluck(result, 'id');
                            var scores = _.pluck(result, 'score');

                            // write back to cache
                            Cache.mzadd(Const.CELL_PERSON_SETS, q.cell, scores, ids);

                            return callback(null, ids);
                        });
                    }
                    else {
                        return callback(null, personIds);
                    }
                }
            ], function (err, results) {

                if (err) {
                    console.error(err);
                    return reply(err);
                }

                return reply(null, results);
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
                text: selectOwn +
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

            Cache.hmset(Const.USER_HASHES, personId, personObj, function (err) {

                if (err) {
                    console.error(err);
                    return reply(err);
                }

                console.log('Received device token %s for personId %s', request.payload.device, personId);
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
                    gender: Joi.number().min(0).max(3).default(0),
                    yob: Joi.number().min(1900).max(2010).default(0),
                    bio: Joi.string().max(2000).default('.')
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

                        p.id = personId;
                        Cache.hmset(Const.PERSON_HASHES, personId, p);
                        return callback(null);
                    });
                }
            ], function (err) {

                if (err) {
                    console.error(err);
                    return reply(err);
                }

                return reply(null, p);
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
                        name: 'person_cell_by_id',
                        text: 'SELECT cell, score FROM person WHERE id = $1 AND deleted = false',
                        values: [personId]
                    };

                    request.pg.client.query(queryConfig, function (err, result) {

                        if (err) {
                            request.pg.kill = true;
                            return callback(err);
                        }

                        if (result.rows.length === 0) {
                            return callback(Boom.badRequest(Const.PERSON_NOT_FOUND));
                        }

                        return callback(null, result.rows[0]);
                    });
                },
                function (person, callback) {

                    var oldCell = person.cell;
                    var newCell = p.cell;
                    Cache.zchangekey(Const.CELL_PERSON_SETS, oldCell, newCell, person.score, personId, function (err) {
                        if (err) {
                            return callback(err);
                        }
                        return callback(null);
                    });
                },
                function (callback) {
                    var queryConfig = {
                        name: 'person_update_location',
                        text: 'UPDATE person SET cell = $1, coords = ST_SetSRID(ST_MakePoint($2, $3), 4326), ut = $4 ' +
                              'WHERE id = $5 AND deleted = false ' +
                              'RETURNING id',
                        values: [p.cell, p.lon, p.lat, _.now(), personId]
                    };

                    request.pg.client.query(queryConfig, function (err, result) {

                        if (err) {
                            request.pg.kill = true;
                            return callback(err);
                        }

                        if (result.rows.length === 0) {
                            return callback(Boom.badRequest(Const.PERSON_UPDATE_LOCATION_FAILED));
                        }

                        return callback(null, result);
                    });
                }
            ], function (err, results) {

                if (err) {
                    console.error(err);
                    return reply(err);
                }

                return reply(null, results.rows[0]);
            });
        }
    });

    next();
};


exports.register.attributes = {
    name: 'person'
};


internals.searchPersonIdByCellFromDB = function (request, callback) {

    var select = 'SELECT id, score FROM person ';
    var where = 'WHERE score >= $1 AND score <= $2 AND cell = $3 AND verified = true AND deleted = false ';
    var order = 'ORDER BY score DESC ';
    var limit = 'LIMIT 50';

    var queryValues = [request.query.min, request.query.max, request.query.cell];
    var queryConfig = {
        name: 'person_by_cell',
        text: select + where + order + limit,
        values: queryValues
    };

    request.pg.client.query(queryConfig, function (err, result) {

        if (err) {
            console.error(err);
            request.pg.kill = true;
            return callback(err);
        }

        return callback(null, result.rows);
    });
};


internals.searchPersonByIdsFromDB = function (request, personIds, callback) {

    var parameterList = Utils.parametersString(2, personIds.length);
    // Adding more conditions is to speed up the where-in search
    var where = 'WHERE cell = $1 AND verified = true AND deleted = false AND id in ' + parameterList;
    var order = 'ORDER BY score DESC ';
    var limit = 'LIMIT 50';

    var queryValues = [request.query.cell];
    var queryConfig = {
        // Warning: DO NOT give a name to this query since it has variable parameters
        text: selectInfo + where + order + limit,
        values: queryValues.concat(personIds)
    };

    request.pg.client.query(queryConfig, function (err, result) {

        if (err) {
            console.error(err);
            request.pg.kill = true;
            return callback(err);
        }

        return callback(null, result.rows);
    });
};
