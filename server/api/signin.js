var Cache = require('../cache');
var Hoek = require('hoek');


exports.register = function (server, options, next) {

    options = Hoek.applyToDefaults({ basePath: '' }, options);

    // Existing person signin
    server.route({
        method: 'GET',
        path: options.basePath + '/signin',
        config: {
            auth: {
                strategy: 'simple'
            }
        },
        handler: function (request, reply) {

            Cache.generateBearerToken(request.auth.credentials.id, request.auth.credentials.name, function (err, token) {

                if (err) {
                    console.error(err);
                    request.pg.kill = true;
                    return reply(err);
                }

                var response = request.auth.credentials;
                response.token = token;

                reply(null, response);
            });
        }
    });

    next();
};


exports.register.attributes = {
    name: 'signin'
};
