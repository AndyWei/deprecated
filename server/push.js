//  Copyright (c) 2015 Joyy Inc. All rights reserved.


var Apn = require('apn');
var Async = require('async');
var Cache = require('./cache');
var Const = require('./constants');
var _ = require('lodash');

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


exports.notify = internals.notify = function (fromPersonId, toPersonId, message, messageType) {

    Async.waterfall([
        function (next) {

            Cache.hgetall(Const.USER_HASHES, toPersonId, function (err, toPerson) {
                if (err) {
                    return next(err);
                }

                if (!toPerson.device || !toPerson.service) {
                    var error = new Error(Const.DEVICE_TOKEN_NOT_FOUND + 'toPersonId = ' + toPersonId);
                    return next(error);
                }

                next(null, toPerson);
            });
        },
        function (toPerson, next) {
// add fromPerson name lookup
            switch(toPerson.service) {
                case Const.NotificationServiceType.APN:
                    internals.apnSend(toPerson.device, toPerson.badge, message, messageType);
                    break;
                case Const.NotificationServiceType.GCM:
                    internals.gcmSend();
                    break;
                case Const.NotificationServiceType.MPN:
                    internals.mpnSend();
                    break;
                default:
                    var error = new Error(Const.DEVICE_TOKEN_INVALID + 'toPersonId = ' + toPersonId);
                    return next(error);
            }
            next(null);
        },
        function (next) {

            Cache.hincrby(Const.USER_HASHES, toPersonId, 'badge', 1, function (err) {

                if (err) {
                    return next(err);
                }

                next(null);
            });
        }
    ], function (err) {

        if (err) {
            console.err(err);
        }

        return;
    });
};


// exports.mnotify = function (personIds, message, body) {

//     if (!personIds || personIds.length === 0) {
//         return;
//     }

//     _.forEach(personIds, function (id) {

//         if (!id) {
//             return;
//         }

//         internals.notify(id, message, body, function (err) {

//             if (err) {
//                 console.error(err);
//             }
//         });
//     });
// };


internals.apnSend = function (device, badge, message, messageType) {

    var apnDevice = new Apn.Device(device);
    var notification = new Apn.Notification();

    if (_.isString(badge)) {
        badge = parseInt(badge, 10);
    }

    notification.badge = badge + 1;
    notification.expiry = Math.floor(_.now() / 1000) + 3600; // Expires 1 hour from now.
    notification.sound = 'default';
    notification.alert = message;
    notification.payload = {'type': messageType};

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
