//  Copyright (c) 2015 Joyy Inc. All rights reserved.

var Async = require('async');
var Boom = require('boom');
var Cache = require('../cache');
var Const = require('../constants');
var Hoek = require('hoek');
var Joi = require('joi');
var Utils = require('../utils');
var _ = require('lodash');

var internals = {};
var selectAll = 'SELECT id, username, avatar, gender, yob, wcnt, score FROM person ';


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
                    id: Joi.array().single(true).unique().max(Const.PERSON_PER_QUERY).items(Joi.string().regex(/^[0-9]+$/).max(19))
                }
            }
        },
        handler: function (request, reply) {

            var r = request.query;
            var personIds = r.id;

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


    // Get person id list in the cell. auth.
    // There is a (zip, cell) store in Cache to maintain the mapping relationship, which is to de-couple zip and cell
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
                    gender: Joi.string().allow('M', 'F', 'X').required(),
                    zip: Joi.string().min(2).max(14).required(),
                    min: Joi.number().integer().default(0), // the minimum score, the search will include this value
                    max: Joi.number().positive().integer().default(Number.MAX_SAFE_INTEGER) // the maximum score, the search will include this value
                }
            }
        },
        handler: function (request, reply) {

            var r = request.query;
            var zip = r.gender + r.zip;
            Async.auto({
                cell: function (callback) {
                    internals.getCellFromZip(zip, function (err, result) {
                        if (err) {
                            return callback(err);
                        }

                        return callback(null, result);
                    });
                },
                cacheRecordCount: ['cell', function (callback, results) {
                    Cache.zcard(Const.CELL_PERSON_SETS, results.cell, function (err, result) {
                        if (err) {
                            console.error(err);
                            return callback(null, 0); // continue search in DB
                        }

                        return callback(null, result);
                    });
                }],
                readCache: ['cacheRecordCount', function (callback, results) {
                    if (results.cacheRecordCount === 0) {
                         return callback(null, null);
                    }

                    Cache.zrevrangebyscore(Const.CELL_PERSON_SETS, results.cell, r.max, r.min, Const.PERSON_PER_QUERY, function (err, result) {
                        if (err) {
                            console.error(err);
                            return callback(null, null); // continue search in DB
                        }

                        if (result.length === 0) {
                            return callback(null, null); // continue search in DB
                        }

                        return callback(Const.CACHE_HIT, result);
                    });
                }],
                readDB: ['readCache', function (callback, results) {

                    internals.searchPersonIdByCellFromDB(request, results.cell, function (err, result) {

                        if (result.length === 0) {
                            return callback(null, []);
                        }

                        var ids = _.pluck(result, 'id');
                        var scores = _.pluck(result, 'score');

                        // write back to cache
                        Cache.mzadd(Const.CELL_PERSON_SETS, results.cell, scores, ids);

                        return callback(null, ids);
                    });
                }]
            }, function (err, results) {

                if (err === Const.CACHE_HIT) {
                    return reply(null, results.readCache);
                }

                if (err) {
                    console.error(err);
                    return reply(err);
                }

                return reply(null, results.readDB);
            });
        }
    });


    // get a person's own profile. auth.
    server.route({
        method: 'GET',
        path: options.basePath + '/person/me',
        config: {
            auth: {
                strategy: 'token'
            }
        },
        handler: function (request, reply) {

            var queryConfig = {
                name: 'person_read_profile',
                text: selectAll +
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

            var username = request.auth.credentials.username;
            var personObj = {
                service: request.payload.service,
                device: request.payload.device,
                badge: request.payload.badge
            };

            Cache.hmset(Const.USER_HASHES, username, personObj, function (err) {

                if (err) {
                    console.error(err);
                    return reply(err);
                }

                console.log('Received device token %s for user %s', request.payload.device, username);
                reply(null, {username: username});
            });
        }
    });


    // update a person's profile. auth.
    server.route({
        method: 'POST',
        path: options.basePath + '/person/me',
        config: {
            auth: {
                strategy: 'token'
            },
            validate: {
                payload: {
                    avatar: Joi.string().required(),
                    gender: Joi.string().allow('M', 'F', 'X').required(),
                    yob: Joi.number().min(1900).max(2010).required(),
                    lang: Joi.string().required()
                }
            }
        },
        handler: function (request, reply) {

            var r = request.payload;
            var personId = request.auth.credentials.id;

            Async.waterfall([

                function (callback) {

                    var queryConfig = {
                        name: 'person_write_profile',
                        text: 'UPDATE person SET avatar = $1, gender = $2, yob = $3, lang = $4, ut = $5 ' +
                              'WHERE id = $6 AND deleted = false ' +
                              'RETURNING id',
                        values: [r.avatar, r.gender, r.yob, r.lang, _.now(), personId]
                    };

                    request.pg.client.query(queryConfig, function (err, result) {

                        if (err) {
                            request.pg.kill = true;
                            return callback(err);
                        }

                        if (result.rows.length === 0) {
                            return callback(Boom.badRequest(Const.PERSON_UPDATE_PROFILE_FAILED));
                        }

                        r.id = personId;
                        delete r.lang;

                        Cache.hmset(Const.PERSON_HASHES, personId, r);
                        return callback(null);
                    });
                }
            ], function (err) {

                if (err) {
                    console.error(err);
                    return reply(err);
                }

                return reply(null, r);
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
                    zip: Joi.string().min(2).max(14).required(), // E.g., US94555
                    cell: Joi.string().min(3).max(12).required() // E.g., MUS9
                }
            }
        },
        handler: function (request, reply) {

            var r = request.payload;
            var personId = request.auth.credentials.id;
            var zip = r.cell.charAt(0) + r.zip; // MUS94555

            Async.auto({
                person: function (callback) {
                    internals.readPersonById(request, function (err, result) {

                        if (err) {
                            return callback(err);
                        }

                        return callback(null, result);
                    });
                },
                updateDB: ['person', function (callback, results) {
                    if (zip === results.person.zip) {
                        return callback(null, null);
                    }

                    var queryConfig = {
                        name: 'person_update_location',
                        text: 'UPDATE person SET zip = $1, coords = ST_SetSRID(ST_MakePoint($2, $3), 4326), ut = $4 ' +
                              'WHERE id = $5 AND deleted = false ' +
                              'RETURNING id',
                        values: [zip, r.lon, r.lat, _.now(), personId]
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
                }],
                newCell: function (callback) {
                    internals.getCellFromZip(zip, function (err, result) {
                        if (err) {
                            return callback(err);
                        }

                        return callback(null, result);
                    });
                },
                updateCell: ['newCell', 'person', function (callback, results) {

                    var oldCell = r.cell;
                    var newCell = results.newCell;
                    if (oldCell === newCell) {
                        return callback(null, newCell);
                    }

                    Cache.zchangekey(Const.CELL_PERSON_SETS, oldCell, newCell, results.person.score, personId, function (err) {
                        if (err) {
                            return callback(err);
                        }
                        return callback(null, newCell);
                    });
                }]
            }, function (err, results) {

                if (err) {
                    console.error(err);
                    return reply(err);
                }

                var response = {
                    cell: results.updateCell
                };
                return reply(null, response);
            });
        }
    });

    next();
};


exports.register.attributes = {
    name: 'person'
};


internals.searchPersonIdByCellFromDB = function (request, cell, callback) {

    var select = 'SELECT id, score FROM person ';
    var where = 'WHERE score >= $1 AND score <= $2 AND position($3 in zip) = 1 AND deleted = false ';
    var order = 'ORDER BY score DESC ';
    var limit = 'LIMIT 50';

    var queryValues = [request.query.min, request.query.max, cell];
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

    var parameterList = Utils.parametersString(1, personIds.length);
    // Adding more conditions is to speed up the where-in search
    var where = 'WHERE deleted = false AND id in ' + parameterList;
    var order = 'ORDER BY score DESC ';
    var limit = 'LIMIT 50';

    var queryConfig = {
        // Warning: DO NOT give a name to this query since it has variable parameters
        text: selectAll + where + order + limit,
        values: personIds
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


internals.readPersonById = function (request, reply) {

    var personId = request.auth.credentials.id;
    Async.auto({
        readCache: function (callback) {
            Cache.hgetall(Const.PERSON_HASHES, personId, function (err, result) {
                if (err) {
                    console.error(err);
                    return callback(null);
                }

                return callback(Const.CACHE_HIT, result);
            });
        },
        readDB: ['readCache', function (callback) {
            var queryConfig = {
                name: 'person_read_zip_by_id',
                text: selectAll + 'WHERE id = $1 AND deleted = false',
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
        }]
    }, function (err, results) {

        if (err === Const.CACHE_HIT) {
            return reply(null, results.readCache);
        }

        if (err) {
            console.error(err);
            return reply(err);
        }

        return reply(null, results.readDB);
    });
};


internals.getCellFromZip = function (zip, reply) {

    Async.auto({
        cell: function (callback) {
            Cache.get(Const.ZIP_CELL_PAIRS, zip, function (err, result) {
                if (err) {
                    return callback(err);
                }

                var cell = result;
                if (!cell) {
                    cell = zip.substr(0, 3); // Use Gender + CountryCode as default cells, e.g., MUS
                }

                return callback(Const.CACHE_HIT, cell);
            });
        },
        personCount: ['cell', function (callback, results) {

            Cache.zcard(Const.CELL_PERSON_SETS, results.cell, function (err, result) {
                if (err) {
                    return callback(err);
                }

                return callback(null, result);
            });
        }],
        split: ['personCount', function (callback, results) {

            var newCell = results.cell;
            if (results.personCount > Const.MAX_PERSON_COUNT_PER_CELL) {

                newCell = zip.substr(0, newCell.length + 1); // Use one more letter as new cell
                Cache.set(Const.ZIP_CELL_PAIRS, zip, newCell);
            }
            return callback(null, newCell);
        }]
    }, function (err, results) {

        if (err === Const.CACHE_HIT) {
            return reply(null, results.cell);
        }

        if (err) {
            console.error(err);
            return reply(err);
        }

        return reply(null, results.split);
    });
};
