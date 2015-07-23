var Apn = require('apn');
var Async = require('async');
var Cache = require('./cache');
var Const = require('./constants');
var _ = require('underscore');

var exports = module.exports = {};
var internals = {};

var apnConnection = null;

var rootFolder = process.cwd();

var apnOptions = {
    'pfx': rootFolder + '/cert/dev.p12',
    'passphrase': ''
};

exports.connect = internals.connect = function () {
    apnConnection = new Apn.Connection(apnOptions);
};


exports.notify = internals.notify = function (userId, title, body, callback) {

    var badgeKey = 'badge' + userId;

    Async.waterfall([
        function (next) {

            var serviceTokenKey = userId;
            var keys = [serviceTokenKey, badgeKey];

            Cache.mget(Const.DEVICE_TOKEN_CACHE, keys, function (err, results) {
                if (err) {
                    return next(err);
                }

                var serviceToken = results[0];
                var badge = Number(results[1] || '0');

                if (!serviceToken) {
                    return next(new Error('Device token missing. user_id = ' + userId));
                }

                var fields = serviceToken.split(':');
                var service = fields[0];
                var token = fields[1];
                next(null, service, token, badge);
            });
        },
        function (service, token, badge, next) {

            switch(service) {
                case 'apn':
                    internals.apnSend(token, badge, title, body);
                    break;
                case 'gcm':
                    internals.gcmSend();
                    break;
                case 'mpn':
                    internals.mpnSend();
                    break;
                default:
                    return next(Const.DEVICE_TOKEN_INVALID);
            }
            next(null);
        },
        function (next) {

            Cache.incr(Const.DEVICE_TOKEN_CACHE, badgeKey, function (err) {

                if (err) {
                    return next(err);
                }

                next(null);
            });
        }
    ], function (err) {

        if (err) {
            return callback(err);
        }

        callback(null, userId);
    });
};


exports.mnotify = function (userIds, title, body) {

    if (!userIds || userIds.length === 0) {
        return;
    }

    _.each(userIds, function (id) {

        if (!id) {
            return;
        }

        internals.notify(id, title, body, function (err) {

            if (err) {
                console.error(err);
            }
        });
    });
};


internals.apnSend = function (token, badge, title, body) {

    var device = new Apn.Device(token);
    var notification = new Apn.Notification();

    notification.badge = badge + 1;
    notification.expiry = Math.floor(Date.now() / 1000) + 3600; // Expires 1 hour from now.
    notification.sound = 'default';
    notification.alert = title;
    notification.payload = {'message': body};

    var connection = apnConnection;

    if (connection) {
        connection.pushNotification(notification, device);
    }
    else {
        console.error('No APN connection');
    }
};


internals.gcmSend = function () {

};


internals.mpnSend = function () {

};
