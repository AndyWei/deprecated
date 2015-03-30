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
            Token.generate(userId, function (err, generatedToken) {

                if (err) {
                    console.error(err);
                    request.pg.kill = true;
                    return reply(err);
                }

                var response = request.auth.credentials;
                response.token = generatedToken;

                reply(null, response);
            });
        }
    });

    next();
};


exports.register.attributes = {
    name: 'signin'
};
