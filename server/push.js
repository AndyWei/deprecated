var Apn = require('apn');
var Async = require('async');
var Token = require('./token');
var c = require('./constants');

var internals = {};

var apnConnection = null;

var rootFolder = process.cwd();

var apnOptions = {
    'pfx': rootFolder + '/cert/dev.p12',
    'passphrase': ''
};


exports.connect = function () {
    apnConnection = new Apn.Connection(apnOptions);
};


exports.send = function (recipientId, title, body, callback) {

    Async.waterfall([
        function (next) {

            Token.getDeviceTokenObject(recipientId, function (err, tokenObj) {
                if (err) {
                    return next(err);
                }

                next(null, tokenObj);
            });
        },
        function (tokenObj, next) {

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
                    return next({ error: c.DEVICE_TOKEN_INVALID });
            }
            next(null, tokenObj);
        },
        function (tokenObj, next) {

            tokenObj.badge += 1;

            Token.setDeviceTokenObject(recipientId, tokenObj, function (err, userIdString) {

                if (err) {
                    return next(err);
                }

                next(null, userIdString);
            });
        }
    ], function (err, userIdString) {

        if (err) {
            console.error(err);
            return callback(err);
        }

        callback(null, userIdString);
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
