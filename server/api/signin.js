var Hoek = require('hoek');
var Token = require('../token');


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
            Token.generateBearerToken(userId, userName, function (err, token) {

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
