var Enum = require('enum');


var exports = module.exports = {};

// cache dataset settings
exports.API_TOKEN_CACHE = {
    segment: 'apit',
    ttl: 60 * 60
};

exports.JOYY_DEVICE_TOKEN_CACHE = {
    segment: 'jydt'
};

exports.JOYYOR_DEVICE_TOKEN_CACHE = {
    segment: 'jrdt'
};

exports.ORDER_COMMENTS_COUNT_CACHE = {
    segment: 'occt',
    ttl: 30 * 24 * 60 * 60
};

exports.USER_NAME_ID_CACHE = {
    segment: 'unid',
    ttl: 30 * 24 * 60 * 60
};

// consts
exports.AUTO_USERNAME_LENGTH = 5;
exports.BCRYPT_ROUND = 10;
exports.DEGREE_FACTOR = 0.0089827983;
exports.TOKEN_LENGTH = 20;

//Error strings
exports.ACCOUNT_NOT_FOUND = 'The joyyor stripe account is not found.';

exports.BID_REVOKE_FAILED = 'The bid is not in active status, cannot be revoked.';

exports.BID_UPDATE_FAILED = 'The order is either not found or not in active status, cannot be bidded.';

exports.COORDINATE_INVALID = 'Lon and lat should occur together.';

exports.DEVICE_TOKEN_NOT_FOUND = 'The device token of the user not found';

exports.DEVICE_TOKEN_INVALID = 'The device token of the user is invalid';

exports.EMAIL_IN_USE = 'Email already in use.';

exports.ORDER_CREATE_FAILED = 'The order has not been created.';

exports.ORDER_NOT_FOUND = 'The order is not found.';

exports.ORDER_REVOKE_FAILED = 'The order is either not found or not in active status, cannot be revoked.';

exports.ORDER_UPDATE_FAILED = 'The order is either not found or not in active status, cannot be updated.';

exports.ORDER_UPDATE_WORKING_STATUS_FAILED = 'The order cannot be updated by the winner.';

exports.QUERY_FAILED = 'Error when running query.';

exports.QUERY_INVALID = 'The query must contain at least one parameter.';

exports.RECORD_NOT_FOUND = 'Query excuted but no record found.';

exports.ORDER_STRIPE_TOKEN_NOT_FOUND = 'The payment token is not found, payment failed.';

exports.TOKEN_INVALID = 'Token is invalid';

exports.USER_NOT_FOUND = 'User not found.';

exports.USER_UPDATE_FAILED = 'User record update failed.';

exports.Role = new Enum({
    user: 0,
    admin: 1,
    test: 2,
    robot: 3
});

