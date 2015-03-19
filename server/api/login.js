var Hoek = require('hoek');
var Token = require('../token');


exports.register = function (server, options, next) {

    options = Hoek.applyToDefaults({ basePath: '' }, options);

    // new user signup
    server.route({
        method: 'GET',
        path: options.basePath + '/login',
        config: {
            auth: {
                strategy: 'simple'
            }
        },
        handler: function (request, reply) {

            var userId = request.auth.credentials.id;
            Token.generate(userId, function (err, generatedToken) {

                if (err) {
                    return reply(err);
                }

                reply(null, {token: generatedToken});
            });
        }
    });

    next();
};


exports.register.attributes = {
    name: 'login'
};
