var Hoek = require('hoek');
var Joi = require('joi');


exports.register = function (server, options, next) {

    options = Hoek.applyToDefaults({ basePath: '' }, options);

    // get all love received by the current user. auth.
    server.route({
        method: 'GET',
        path: options.basePath + '/love/me',
        config: {
            auth: {
                strategy: 'token'
            },
            validate: {
                query: {
                    status: Joi.number().min(0).max(100).default(0),
                    before: Joi.string().regex(/^[0-9]+$/).max(19).default('9223372036854775807')
                }
            }
        },
        handler: function (request, reply) {

            var q = request.query;

            var select = 'SELECT sender_id FROM love ';
            var where  = 'WHERE receiver_id = $1 AND status = $2 AND id < $3 AND deleted = false ';
            var sort   = 'ORDER BY id DESC LIMIT 10';
            var queryConfig = {
                name: 'love_me',
                text: select + where + sort,
                values: [request.auth.credentials.id, q.status, q.before]
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

    next();
};


exports.register.attributes = {
    name: 'love'
};
