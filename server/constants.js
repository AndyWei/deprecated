var exports = module.exports = {};


// cache dataset settings
exports.AUTH_TOKEN_CACHE = {
    segment: 'attk',
    ttl: 30 * 60
};

exports.DEVICE_TOKEN_CACHE = {
    segment: 'dvtk'
};

exports.MEDIA_COMMENT_COUNT_CACHE = {
    segment: 'mcct',
    ttl: 24 * 60 * 60
};


// consts
exports.BCRYPT_ROUND = 10;
exports.DEGREE_FACTOR = 0.0089827983;
exports.TOKEN_LENGTH = 20;

// Error strings
exports.AUTH_TOKEN_INVALID = 'The authentication token is invalid.';

exports.COMMENT_CREATE_FAILED = 'The comment has not been created.';

exports.DEVICE_TOKEN_NOT_FOUND = 'The device token of the user not found.';

exports.DEVICE_TOKEN_INVALID = 'The device token of the user is invalid.';

exports.EMAIL_IN_USE = 'Email already in use.';

exports.FILENAME_MISSING = 'The upload file must have a name.';

exports.MEDIA_CREATE_FAILED = 'The media file has been uploaded to s3, but create media record failed.';

exports.PERSON_CREATE_FAILED = 'The person record has not been created.';

exports.PERSON_NOT_FOUND = 'The person record is not found.';

exports.PERSON_UPDATE_FAILED = 'The person record update failed.';


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
