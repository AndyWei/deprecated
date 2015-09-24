//  Copyright (c) 2015 Joyy Inc. All rights reserved.


var Apn = require('apn');
var Async = require('async');
var Boom = require('boom');
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


exports.notify = internals.notify = function (request, fromUsername, toUsername, message, messageType) {

    Async.auto({
        toPerson: function (callback) {
            var queryConfig = {
                name: 'person_read_device_fields_by_id',
                text: 'SELECT id, service, device FROM person ' +
                      'WHERE username = $1 AND deleted = false',
                values: [toUsername]
            };

            request.pg.client.query(queryConfig, function (err, result) {

                if (err) {
                    request.pg.kill = true;
                    return callback(err);
                }

                if (result.rows.length === 0) {
                    return callback(Boom.badRequest(Const.PERSON_NOT_FOUND));
                }

                return callback(null, result.rows[0]);
            });
        },
        badge: ['toPerson', function (callback, results) {

            Cache.hget(Cache.PersonStore, results.toPerson.id, 'badge', function (err, result) {

                if (err) {
                    return callback(err);
                }

                callback(null, result);
            });
        }],
        send: ['toPerson', 'badge', function (callback, results) {

            var service = Number(results.toPerson.service);
            var fullMessage = '@' + fromUsername + ': ' + message;
            switch(service) {
                case Const.NotificationServiceType.APN:
                    internals.apnSend(results.toPerson.device, results.badge, fullMessage, messageType);
                    break;
                case Const.NotificationServiceType.GCM:
                    internals.gcmSend();
                    break;
                case Const.NotificationServiceType.MPN:
                    internals.mpnSend();
                    break;
                default:
                    var err = new Error(Const.DEVICE_TOKEN_INVALID + ' toUsername = ' + toUsername);
                    return callback(err);
            }

            return callback(null);
        }]
    }, function (err) {

        if (err) {
            console.error(err);
            return;
        }

        Cache.hincrby(Cache.UsernameStore, toUsername, 'badge', 1);

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
