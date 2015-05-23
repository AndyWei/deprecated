var Apn = require('apn');
var Async = require('async');
var Cache = require('./cache');
var c = require('./constants');
var _ = require('underscore');


var internals = {};

var jyApnConnection = null;
var jrApnConnection = null;

var rootFolder = process.cwd();

var jyApnOptions = {
    'pfx': rootFolder + '/cert/dev.p12',
    'passphrase': ''
};

var jrApnOptions = {
    'pfx': rootFolder + '/cert/joyyor_dev.p12',
    'passphrase': ''
};

exports.connect = function () {
    jyApnConnection = new Apn.Connection(jyApnOptions);
    jrApnConnection = new Apn.Connection(jrApnOptions);
};


exports.notify = internals.notify = function (app, userId, title, body, callback) {

    var dataset = (app === 'joyy') ? c.JOYY_DEVICE_TOKEN_CACHE : c.JOYYOR_DEVICE_TOKEN_CACHE;
    var badgeKey = 'badge' + userId;

    Async.waterfall([
        function (next) {

            var serviceTokenKey = userId;
            var keys = [serviceTokenKey, badgeKey];

            Cache.mget(dataset, keys, function (err, results) {
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
                    internals.apnSend(app, token, badge, title, body);
                    break;
                case 'gcm':
                    internals.gcmSend();
                    break;
                case 'mpn':
                    internals.mpnSend();
                    break;
                default:
                    return next(c.DEVICE_TOKEN_INVALID);
            }
            next(null);
        },
        function (next) {

            Cache.incr(dataset, badgeKey, function (err) {

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


exports.mnotify = function (app, userIds, title, body) {

    if (!userIds || userIds.length === 0) {
        return;
    }

    _.each(userIds, function (id) {

        if (!id) {
            return;
        }

        internals.notify(app, id, title, body, function (err) {

            if (err) {
                console.error(err);
            }
        });
    });
};


internals.apnSend = function (app, token, badge, title, body) {

    var device = new Apn.Device(token);
    var notification = new Apn.Notification();

    notification.badge = badge + 1;
    notification.expiry = Math.floor(Date.now() / 1000) + 3600; // Expires 1 hour from now.
    notification.sound = 'default';
    notification.alert = title;
    notification.payload = {'message': body};

    var connection = (app === 'joyy') ? jyApnConnection : jrApnConnection;
    connection.pushNotification(notification, device);
};


internals.gcmSend = function () {

};


internals.mpnSend = function () {

};
