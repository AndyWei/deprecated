var Hoek = require('hoek');
var TokenManager = require('../tokenmanager');


exports.register = function (server, options, next) {

    options = Hoek.applyToDefaults({ basePath: '' }, options);

    // new user signup
    server.route({
        method: 'GET',
        path: options.basePath + '/token',
        config: {
            auth: {
                strategy: 'simple'
            }
        },
        handler: function (request, reply) {

            var userId = request.auth.credentials.id;
            TokenManager.generate(userId, function (err, generatedToken) {

                if (err) {
                    return reply(err);
                }

                var response = {
                    token: generatedToken
                };

                reply(null, response);
            });
        }
    });

    next();
};


exports.register.attributes = {
    name: 'token'
};
