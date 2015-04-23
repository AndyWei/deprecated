var Apn = require('apn');
var Async = require('async');
var Token = require('./token');
var c = require('./constants');

var apnConnection = null;
var apnOptions = {};
var internals = {};

exports.connect = function () {
    apnConnection = new Apn.Connection(apnOptions);
};


// Generate a 20 character alpha-numeric token and store it in bearerTokenCache
exports.send = function (receiverId, title, body, reply) {

    Async.waterfall([
        function (callback) {

            Token.getDeviceTokenObject(receiverId, function (err, tokenObj) {
                if (err) {
                    return callback(c.DEVICE_TOKEN_NOT_FOUND);
                }

                callback(null, tokenObj);
            });
        },
        function (tokenObj, callback) {

            switch(tokenObj.service) {
                case c.PushService.apn.value:
                    internals.apnSend(tokenObj, title, body);
                    break;
                case c.PushService.gcm.value:
                    internals.gcmSend();
                    break;
                case c.PushService.mpn.value:
                    internals.mpnSend();
                    break;
                default:
                    return callback(c.DEVICE_TOKEN_INVALID);
            }
            callback(null, tokenObj);
        },
        function (tokenObj, callback) {

            tokenObj.badge += 1;

            Token.setDeviceTokenObject(receiverId, tokenObj, function (err, userIdString) {

                if (err) {
                    return callback(err);
                }

                callback(null, userIdString);
            });
        }
    ], function (err, userIdString) {

        if (err) {
            console.error(err);
            return reply(err);
        }

        reply(null, userIdString);
    });
};


internals.apnSend = function (tokenObj, title, body) {

    var device = new Apn.Device(tokenObj.token);
    var notification = new Apn.Notification();

    notification.badge = tokenObj.badge + 1;
    notification.expiry = Math.floor(Date.now() / 1000) + 3600; // Expires 1 hour from now.
    notification.sound = 'default';
    notification.alert = title;
    notification.payload = {'message': body};

    apnConnection.pushNotification(notification, device);
};


internals.gcmSend = function () {

};


internals.mpnSend = function () {

};
