var exports = module.exports = {};


/*
 * cache dataset settings
 */

// Simple pairs. key = authToken, value = personId
exports.AUTHTOKEN_PERSON_PAIRS = {
    segment: 'A',
    ttl: 60 * 60
};

// Lists. key = mediaId, values = last 3 comments
exports.MEDIA_COMMENT_LISTS = {
    segment: 'C',
    size: 3
};

//// Media
// Hash. key = personId, fields = {name, token, badge, invite_count, friend_count, ...}
exports.MEDIA_HASHES = {
    segment: 'm'
};

// SortedSet. key = cellId, value = mediaId, score = media.ct
exports.CELL_MEDIA_SETS = {
    segment: 'M',
    size: 1000
};

//// Person
// Hash. key = personId, fields = {name, token, badge, invite_count, friend_count, ...}
exports.PERSON_HASHES = {
    segment: 'p'
};

// SortedSet. key = cellId, value = personId, score = personScore
exports.CELL_PERSON_SETS = {
    segment: 'P'
};

// consts
exports.BCRYPT_ROUND = 10;
exports.DEGREE_FACTOR = 0.0089827983;
exports.TOKEN_LENGTH = 20;
exports.MAX_ID = '9223372036854775807';

exports.MEDIA_LIMIT = 20;  // the max number of media records returned per query
exports.PERSON_LIMIT = 20; // the max number of person records returned per query

// Error strings
exports.AUTH_TOKEN_INVALID = 'The authentication token is invalid.';

exports.COMMENT_CREATE_FAILED = 'Failed to create comment record.';

exports.DEVICE_TOKEN_NOT_FOUND = 'The device token of the user not found. Cannot send push notification.';
exports.DEVICE_TOKEN_INVALID = 'The device token of the user is invalid.';

exports.EMAIL_IN_USE = 'Email already in use.';

exports.FILENAME_MISSING = 'The upload file must have a name.';

exports.HEART_CREATE_FAILED = 'Failed to create heart record.';
exports.HEART_NOT_ALLOWED = 'Cannot heart yourself.';

exports.MEDIA_CREATE_FAILED = 'The media file has been uploaded to s3, but failed to create media record.';
exports.MEDIA_LIKE_FAILED = 'Failed to like the media record.';

exports.PERSON_CREATE_FAILED = 'Failed to create person record.';
exports.PERSON_INCREASE_HEART_COUNT_FAILED = 'Failed to update the heart count of the person.';
exports.PERSON_NOT_FOUND = 'Failed to find the person record.';
exports.PERSON_UPDATE_LOCATION_FAILED = 'Failed to update the location of the person.';
exports.PERSON_UPDATE_PROFILE_FAILED = 'Failed to update the profile of the person.';


// Role
exports.Role = {
    USER: 0,
    ADMIN: 1,
    TEST: 2,
    ROBOT: 3
};

// org type
exports.OrgType = {
    COM: 0,
    EDU: 1,
    ORG: 2,
    GOV: 3,
    OTHER: 4
};

// push notification service type
exports.NotificationServiceType = {
    APN: 1,
    GCM: 2,
    MPN: 3
};
