//  Copyright (c) 2015 Joyy Inc. All rights reserved.


var exports = module.exports = {};

// consts
exports.IM_DOMAIN = 'joyy.im';
exports.BCRYPT_ROUND = 10;

exports.MAX_ID = '9223372036854775807';

exports.COMMENT_PER_QUERY = 20; // the max number of comment records returned per query
exports.POST_PER_QUERY = 20;    // the max number of post records returned per query
exports.PERSON_PER_QUERY = 50;  // the max number of person records returned per query

exports.PERSON_CELL_SPLIT_THRESHOLD = 10000;  // the threshold to split a person cell
exports.POST_CELL_SPLIT_THRESHOLD   = 800;    // the threshold to split a post cell. This value must smaller than Cache.PostsInCell.size

exports.CACHE_HIT = 'cache_hit';
exports.CACHE_MISS = 'cache_miss';
exports.SKIP_DB_SEARCH = 'skip_db_search';


// Error strings
exports.AUTH_TOKEN_INVALID = 'The authentication token is invalid.';
exports.COMMENT_CREATE_FAILED = 'Failed to create comment record.';
exports.DEVICE_TOKEN_NOT_FOUND = 'The device token of the user not found. Cannot send push notification.';
exports.DEVICE_TOKEN_INVALID = 'The device token of the user is invalid.';
exports.FILENAME_MISSING = 'The upload file must have a name.';
exports.HEART_CREATE_FAILED = 'Failed to create heart record.';
exports.HEART_NOT_ALLOWED = 'Cannot heart yourself.';
exports.PERSON_CREATE_FAILED = 'Failed to create person record.';
exports.PERSON_INCREASE_HEART_COUNT_FAILED = 'Failed to update the heart count of the person.';
exports.PERSON_NOT_FOUND = 'Failed to find the person record.';
exports.PERSON_UPDATE_DEVICE_FAILED = 'Failed to update the profile of the person.';
exports.PERSON_UPDATE_LOCATION_FAILED = 'Failed to update the location of the person.';
exports.PERSON_UPDATE_PROFILE_FAILED = 'Failed to update the profile of the person.';
exports.POST_CREATE_FAILED = 'The file has been uploaded to s3, but failed to create post record.';
exports.POST_LIKE_FAILED = 'Failed to like the post record.';
exports.USERNAME_IN_USE = 'Username already in use.';

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
