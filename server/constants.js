var Enum = require('enum');


var exports = module.exports = {};

// consts
exports.AUTO_USERNAME_LENGTH = 5;
exports.BCRYPT_ROUND = 10;
exports.DEGREE_FACTOR = 0.0089827983;
exports.TOKEN_LENGTH = 20;

//Error strings
exports.BID_REVOKE_FAILED = 'The bid is not in active status, cannot be revoked.';

exports.BID_UPDATE_FAILED = 'The order is either not found or not in active status, cannot be bidded.';

exports.COORDINATE_INVALID = 'Lon and lat should occur together.';

exports.EMAIL_IN_USE = 'Email already in use.';

exports.ORDER_CREATE_FAILED = 'The order has not been created.';

exports.ORDER_REVOKE_FAILED = 'The order is either not found or not in active status, cannot be revoked.';

exports.ORDER_UPDATE_FAILED = 'The order is either not found or not in active status, cannot be updated.';

exports.QUERY_FAILED = 'Error when running query.';

exports.QUERY_INVALID = 'The query must contain at least one parameter.';

exports.RECORD_NOT_FOUND = 'Query excuted but no record found.';

exports.TOKEN_INVALID = 'Token is invalid';

exports.USER_NOT_FOUND = 'User not found.';


// enums
exports.Role = new Enum({
    user: 1,
    admin: 2,
    test: 3,
    robot: 4
});

// exports.UserStatus = new Enum({
//     active: 1,
//     closed: 2,
//     suspended: 3
// });
