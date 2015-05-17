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
                    service: Joi.string().allow('apn', 'gcm', 'mpn'),
                    token: Joi.string().max(100),
                    badge: Joi.number().min(0).max(1000).default(0)
                }
            }
        },
        handler: function (request, reply) {

            var userId = request.auth.credentials.id;
            var serviceTokenKey = userId;
            var badgeKey = 'badge' + userId;
            var keys = [serviceTokenKey, badgeKey];

            var serviceToken = request.payload.service + ':' + request.payload.token;
            var values = [serviceToken, request.payload.badge];

            var dataset = (request.params.app === 'joyy') ? c.JOYY_DEVICE_TOKEN_CACHE : c.JOYYOR_DEVICE_TOKEN_CACHE;

            Cache.mset(dataset, keys, values, function (err) {

                if (err) {
                    console.error(err);
                    return reply(err);
                }

                console.info('App %s: received device token %s for userId %s', request.params.app, request.payload.token, userId);
                reply(null, {token: request.payload.token});
            });
        }
    });

    next();
};


exports.register.attributes = {
    name: 'notification'
};
