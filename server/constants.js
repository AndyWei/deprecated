var Enum = require('enum');


var exports = module.exports = {};

// consts
exports.AUTO_USERNAME_LENGTH = 5;
exports.BCRYPT_ROUND = 10;
exports.DEGREE_FACTOR = 0.0089827983;
exports.TOKEN_LENGTH = 20;

//Error strings

exports.BID_REVOKE_FAILED = 'The bid is not in active status, cannot be revoked.';
exports.EMAIL_IN_USE = 'Email already in use.';
exports.ORDER_REVOKE_FAILED = 'The order is not in active status, cannot be revoked.';
exports.QUERY_FAILED = 'Error when running query.';
exports.RECORD_NOT_FOUND = 'Query excuted but no record found.';
exports.TOKEN_INVALID = 'Token is invalid';
exports.USER_NOT_FOUND = 'User not found.';

// enums
exports.OrderStatus = new Enum({
    active: 1,
    closed: 2,
    ending: 3,
    canceled: 4
});

exports.Role = new Enum({
    user: 1,
    admin: 2,
    test: 3,
    robot: 4
});

exports.UserStatus = new Enum({
    active: 1,
    closed: 2,
    suspended: 3
});
