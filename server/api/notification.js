var Cache = require('../cache');
var Hoek = require('hoek');
var Joi = require('joi');
var c = require('../constants');

exports.register = function (server, options, next) {

    options = Hoek.applyToDefaults({ basePath: '' }, options);

    // new user signup
    server.route({
        method: 'POST',
        path: options.basePath + '/notifications/devices/{app}',
        config: {
            auth: {
                strategy: 'token'
            },
            validate: {
                params: {
                    app: Joi.string().alphanum().lowercase()
                },
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

            var dataset = (request.params.app === 'joyy') ? c.JOYY_DEVICE_TOKEN_CACHE : c.JOYYOR_DEVICE_TOKEN_CACHE;
            Cache.set(dataset, userId, tokenObj, function (err, userIdString) {

                if (err) {
                    console.error(err);
                    return reply(err);
                }

                console.info('App %s: received device token %s for userId %s', request.params.app, request.payload.token, userId);
                reply(null, {userId: userIdString});
            });
        }
    });

    next();
};


exports.register.attributes = {
    name: 'notification'
};
