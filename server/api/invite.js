var Hoek = require('hoek');
var Joi = require('joi');


exports.register = function (server, options, next) {

    options = Hoek.applyToDefaults({ basePath: '' }, options);

    // get all invite for the current user. auth.
    server.route({
        method: 'GET',
        path: options.basePath + '/invite/me',
        config: {
            auth: {
                strategy: 'token'
            },
            validate: {
                query: {
                    status: Joi.number().min(0).max(100).default(0),
                    after: Joi.string().regex(/^[0-9]+$/).max(19).default('0')
                }
            }
        },
        handler: function (request, reply) {

            var userId = request.auth.credentials.id;
            var q = request.query;

            var select = 'SELECT i.id, b.user_id, i.duration, i.category, i.title, i.start_time, i.city, i.address, i.created_at, \
                          ST_X(i.coordinate) AS lon, ST_Y(i.coordinate) AS lat \
                          u.username, u.rating, u.rating_count FROM invite AS i ';
            var join   = 'INNER JOIN jyuser AS u ON u.id = i.user_id ';
            var where  = 'WHERE $1 = ANY(i.invitee_id) AND i.status = $2 AND i.id > $3 AND i.deleted = false ';
            var sort   = 'ORDER BY i.id DESC LIMIT 25';
            var queryConfig = {
                name: 'invite_me',
                text: select + join + where + sort,
                values: [userId, q.status, q.after]
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
    name: 'invite'
};
