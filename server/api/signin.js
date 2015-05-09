var Cache = require('../cache');
var Hoek = require('hoek');


exports.register = function (server, options, next) {

    options = Hoek.applyToDefaults({ basePath: '' }, options);

    // new user signup
    server.route({
        method: 'GET',
        path: options.basePath + '/signin',
        config: {
            auth: {
                strategy: 'simple'
            }
        },
        handler: function (request, reply) {

            var userId = request.auth.credentials.id;
            var userName = request.auth.credentials.username;
            Cache.generateBearerToken(userId, userName, function (err, token) {

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
