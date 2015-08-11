var exports = module.exports = {};


/*
 * cache dataset settings
 */

// Simple pairs. key = authToken, value = personId
exports.AUTHTOKEN_PERSON_PAIRS = {
    key: 'A',
    ttl: 35 * 60
};

//// Comment
// Hash. key = commentId, fields = {id, owner, content, ...}
exports.COMMENT_HASHES = {
    key: 'c'
};

// SortedSet. key = postId, value = commentId, score = comment.ct
exports.POST_COMMENT_SETS = {
    key: 'C',
    size: 1000
};

//// Post
// Hash. key = personId, fields = {filname, uv, badge, likes, comments, ...}
exports.POST_HASHES = {
    key: 't'
};

// SortedSet. key = cellId, value = postId, score = post.ct
exports.CELL_POST_SETS = {
    key: 'T',
    size: 1000
};

//// Person
// Hash. key = personId, fields = {name, device, badge, hearts, friends, ...}
exports.PERSON_HASHES = {
    key: 'p'
};

// SortedSet. key = cellId, value = personId, score = personScore
exports.CELL_PERSON_SETS = {
    key: 'P'
};

//// User
// Hash. key = personId, fields = {device, service, badge}
exports.USER_HASHES = {
    key: 'u'
};

// consts
exports.BCRYPT_ROUND = 10;
exports.DEGREE_FACTOR = 0.0089827983;
exports.TOKEN_LENGTH = 20;
exports.MAX_ID = '9223372036854775807';
exports.MAX_SCORE = 2147483647; // the max value of postgres integer

exports.COMMENT_PER_QUERY = 20; // the max number of comment records returned per query
exports.POST_PER_QUERY = 20;    // the max number of post records returned per query
exports.PERSON_PER_QUERY = 50;  // the max number of person records returned per query

// Error strings
exports.AUTH_TOKEN_INVALID = 'The authentication token is invalid.';

exports.COMMENT_CREATE_FAILED = 'Failed to create comment record.';

exports.DEVICE_TOKEN_NOT_FOUND = 'The device token of the user not found. Cannot send push notification.';
exports.DEVICE_TOKEN_INVALID = 'The device token of the user is invalid.';

exports.EMAIL_IN_USE = 'Email already in use.';

exports.FILENAME_MISSING = 'The upload file must have a name.';

exports.HEART_CREATE_FAILED = 'Failed to create heart record.';
exports.HEART_NOT_ALLOWED = 'Cannot heart yourself.';

exports.PERSON_CREATE_FAILED = 'Failed to create person record.';
exports.PERSON_INCREASE_HEART_COUNT_FAILED = 'Failed to update the heart count of the person.';
exports.PERSON_NOT_FOUND = 'Failed to find the person record.';
exports.PERSON_UPDATE_LOCATION_FAILED = 'Failed to update the location of the person.';
exports.PERSON_UPDATE_PROFILE_FAILED = 'Failed to update the profile of the person.';

exports.POST_CREATE_FAILED = 'The file has been uploaded to s3, but failed to create post record.';
exports.POST_LIKE_FAILED = 'Failed to like the post record.';

// Role
exports.Role = {
    USER: 0,
    ADMIN: 1,
    TEST: 2,
    ROBOT: 3
};

// org type
exports.OrgType = {
    UNKNOWN: 0,
    COM: 1,
    EDU: 2,
    ORG: 3,
    GOV: 4,
    OTHER: 100
};

// push notification service type
exports.NotificationServiceType = {
    APN: 1,
    GCM: 2,
    MPN: 3
};
