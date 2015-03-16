var Enum = require('enum');


var exports = module.exports = {};

// consts
exports.ALPHA_LENGTH = 5;


//Error strings

exports.EmailInUse = 'Email already in use.';
exports.RecordNotFound = 'Query excuted but no record found.';
exports.QueryFailed = 'Error when running query.';
exports.UserNotFound = 'User not found.';

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
