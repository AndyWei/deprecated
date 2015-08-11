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


exports.notify = internals.notify = function (personId, title, body, callback) {

    Async.waterfall([
        function (next) {

            Cache.hgetall(Const.USER_HASHES, personId, function (err, person) {
                if (err) {
                    return next(err);
                }

                if (!person.device || !person.service) {
                    var error = new Error(Const.DEVICE_TOKEN_NOT_FOUND + 'personId = ' + personId);
                    return next(error);
                }

                next(null, person);
            });
        },
        function (person, next) {

            switch(person.service) {
                case Const.NotificationServiceType.APN:
                    internals.apnSend(person.device, person.badge, title, body);
                    break;
                case Const.NotificationServiceType.GCM:
                    internals.gcmSend();
                    break;
                case Const.NotificationServiceType.MPN:
                    internals.mpnSend();
                    break;
                default:
                    var error = new Error(Const.DEVICE_TOKEN_INVALID + 'personId = ' + personId);
                    return next(error);
            }
            next(null);
        },
        function (next) {

            Cache.hincrby(Const.USER_HASHES, personId, 'badge', 1, function (err) {

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

        callback(null, personId);
    });
};


exports.mnotify = function (personIds, title, body) {

    if (!personIds || personIds.length === 0) {
        return;
    }

    _.each(personIds, function (id) {

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


internals.apnSend = function (device, badge, title, body) {

    var apnDevice = new Apn.Device(device);
    var notification = new Apn.Notification();

    if (_.isString(badge)) {
        badge = parseInt(badge, 10);
    }

    notification.badge = badge + 1;
    notification.expiry = Math.floor(_.now() / 1000) + 3600; // Expires 1 hour from now.
    notification.sound = 'default';
    notification.alert = title;
    notification.payload = {'message': body};

    var connection = apnConnection;

    if (connection) {
        connection.pushNotification(notification, apnDevice);
    }
    else {
        console.error('No APN connection');
    }
};


internals.gcmSend = function () {

};


internals.mpnSend = function () {

};
