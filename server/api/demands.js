var Async = require('async');
var AuthPlugin = require('../auth');
var Constants = require("../constants");
var Error = require("../error");
var Hoek = require('hoek');
var Joi = require('joi');
var Pg = require('pg').native;


exports.register = function (server, options, next) {

    options = Hoek.applyToDefaults({ basePath: '' }, options);

    // get a single demand record by its id
    server.route({
        method: 'GET',
        path: options.basePath + '/demand/{id}',
        config: {
            auth: {
                strategy: 'simple',
                scope: 'account'
            }
        },
        handler: function (request, reply) {

            var queryConfig = {
                text: 'SELECT * FROM demands WHERE id = $1',
                values: [request.params.id]
            };

            request.pg.client.query(queryConfig, function (err, result) {

                if (err) {
                    return reply(err);
                }

                if (result.rows.length === 0) {
                    return reply({ message: Error.RecordNotFound }).code(404);
                }

                var json = JSON.stringify(result.rows);

                reply(json);
            });
        }
    });

    next();
};


exports.register.attributes = {
    name: 'demands'
};
