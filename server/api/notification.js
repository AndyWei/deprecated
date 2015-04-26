var Hoek = require('hoek');
var Joi = require('joi');
var Token = require('../token');


exports.register = function (server, options, next) {

    options = Hoek.applyToDefaults({ basePath: '' }, options);

    // new user signup
    server.route({
        method: 'POST',
        path: options.basePath + '/notifications/devices',
        config: {
            auth: {
                strategy: 'token'
            },
            validate: {
                payload: {
                    service: Joi.number().min(1).max(3),
                    token: Joi.string().max(100),
                    badge: Joi.number().min(0).max(1000).default(0)
                }
            }
        },
        handler: function (request, reply) {

            var userId = request.auth.credentials.id;
            var tokenObj = {
                service: request.payload.service,
                token: request.payload.token,
                badge: request.payload.badge
            };

            Token.setDeviceTokenObject(userId, tokenObj, function (err, userIdString) {

                if (err) {
                    console.error(err);
                    return reply(err);
                }

                reply(null, {userId: userIdString});
            });
        }
    });

    next();
};


exports.register.attributes = {
    name: 'notification'
};
