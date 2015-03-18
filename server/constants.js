var Enum = require('enum');


var exports = module.exports = {};

// consts
exports.ALPHA_LENGTH = 5;
exports.BCRYPT_ROUND = 10;
exports.TOKEN_LENGTH = 12;

//Error strings

exports.EMAIL_IN_USE = 'Email already in use.';
exports.TOKEN_INVALID = 'Token is invalid';
exports.RECORD_NOT_FOUND = 'Query excuted but no record found.';
exports.QUERY_FAILED = 'Error when running query.';
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
