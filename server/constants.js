var exports = module.exports = {};


// cache dataset settings
exports.AUTH_TOKEN_CACHE = {
    segment: 'A',
    ttl: 30 * 60
};

exports.COMMENT_CACHE = {
    segment: 'C',
    size: 3
};

exports.COMMENT_COUNT_CACHE = {
    segment: 'c'
};

exports.DEVICE_TOKEN_CACHE = {
    segment: 'D'
};

exports.LIKE_COUNT_CACHE = {
    segment: 'l'
};

exports.MEDIA_CACHE = {
    segment: 'M',
    size: 100
};

exports.MEDIA_COUNT_CACHE = {
    segment: 'm'
};

exports.PERSON_CACHE = {
    segment: 'P',
    size: 100
};

// consts
exports.BCRYPT_ROUND = 10;
exports.DEGREE_FACTOR = 0.0089827983;
exports.TOKEN_LENGTH = 20;
exports.MAX_ID = '9223372036854775807';

// Error strings
exports.AUTH_TOKEN_INVALID = 'The authentication token is invalid.';

exports.COMMENT_CREATE_FAILED = 'Failed to create comment record.';

exports.DEVICE_TOKEN_NOT_FOUND = 'The device token of the user not found.';
exports.DEVICE_TOKEN_INVALID = 'The device token of the user is invalid.';

exports.EMAIL_IN_USE = 'Email already in use.';

exports.FILENAME_MISSING = 'The upload file must have a name.';

exports.HEART_CREATE_FAILED = 'Failed to create heart record.';
exports.HEART_NOT_ALLOWED = 'Cannot heart yourself.';

exports.MEDIA_CREATE_FAILED = 'The media file has been uploaded to s3, but failed to create media record.';

exports.PERSON_CREATE_FAILED = 'Failed to create person record.';
exports.PERSON_INCREASE_HEART_COUNT_FAILED = 'Failed to update the heart count of the person.';
exports.PERSON_NOT_FOUND = 'Failed to find he person record.';
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
    OTHER: 3
};
