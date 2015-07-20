var Cache = require('../cache');
var Hoek = require('hoek');
var Joi = require('joi');
var c = require('../constants');

exports.register = function (server, options, next) {

    options = Hoek.applyToDefaults({ basePath: '' }, options);

    // new user signup
    server.route({
        method: 'POST',
        path: options.basePath + '/notification/device',
        config: {
            auth: {
                strategy: 'token'
            },
            validate: {
                payload: {
                    service: Joi.string().allow('apn', 'gcm', 'mpn').required(),
                    token: Joi.string().max(100).required(),
                    badge: Joi.number().min(0).max(1000).optional().default(0)
                }
            }
        },
        handler: function (request, reply) {

            var pid = request.auth.credentials.id;
            var serviceTokenKey = pid;
            var badgeKey = 'badge' + pid;
            var keys = [serviceTokenKey, badgeKey];

            var serviceToken = request.payload.service + ':' + request.payload.token;
            var values = [serviceToken, request.payload.badge];

            Cache.mset(c.DEVICE_TOKEN_CACHE, keys, values, function (err) {

                if (err) {
                    console.error(err);
                    return reply(err);
                }

                console.info('Received device token %s for pid %s', request.payload.token, pid);
                reply(null, {token: request.payload.token});
            });
        }
    });

    next();
};


exports.register.attributes = {
    name: 'notification'
};
