var Hoek = require('hoek');
var Joi = require('joi');
var c = require('../constants');

exports.register = function (server, options, next) {

    options = Hoek.applyToDefaults({ basePath: '' }, options);

    // get a single order record by its id
    server.route({
        method: 'GET',
        path: options.basePath + '/order/{id}',
        config: {
            auth: {
                strategy: 'simple'
            },
            validate: {
                params: {
                    id: Joi.string().regex(/^[0-9]+$/).max(19)
                }
            }
        },
        handler: function (request, reply) {

            var queryConfig = {
                text: 'SELECT * FROM orders WHERE id = $1',
                values: [request.params.id],
                name: 'orders_select_all_by_id'
            };

            request.pg.client.query(queryConfig, function (err, result) {

                if (err) {
                    return reply(err);
                }

                if (result.rows.length === 0) {
                    return reply({ message: c.RecordNotFound }).code(404);
                }

                var json = JSON.stringify(result.rows);

                reply(json);
            });
        }
    });

    next();
};


exports.register.attributes = {
    name: 'orders'
};
