/*
 * user.cql
 * 
 * Copyright (c) 2015 Joyy Inc. All rights reserved.
 */

USE wink;

/*
 * Description: the main user table
 * Write      : when a user sign up, a row is created
 * TTL        : none
 * Cardinality: equals the number of signedup users 
 * Workload   : both write-heavy and read-heavy
 *
 * @Discussion:
 */
CREATE TABLE IF NOT EXISTS user (
    id                 bigint       ,
    name               list<text>   , -- all the usernames have been used
    phone              list<bigint> , -- all the phone numbers have been used
    deleted            boolean      ,

    followers_count    bigint       , -- the number of followers this user have
    followings_count   bigint       , -- the number of users being followed by this user

    PRIMARY KEY (id)
) WITH COMPACTION = {'class': 'LeveledCompactionStrategy', 'enabled': 'true'};


/*
 * Write      : when a user occurs in a area (via POST to user/location endpoint), a cloumn is created or updated
 * TTL        : none
 * Cardinality: equals the number of signedup users 
 * Workload   : both write-heavy and read-heavy
 *
 * @Discussion:
 */
CREATE TABLE IF NOT EXISTS user_by_name (
    -- account fields created in post user/signup
    name             text    , -- unique username
    id               bigint  ,
    password         text    , -- bcrypt hashed password, it always 60 bytes, however text makes it flexible
    deleted          boolean , -- a deleted username means it can be take by another user

    -- profile fields updated in post profile
    phone            bigint  , -- phone number
    language         text    , -- the language of the user's phone locale
    avatar           text    , -- This field is used for client to generate avatar url. It contains two parts, the region and the filename, in form of regioncode:filename, e.g., "eu:jfk_1064.jpg". Region could be "na", "eu" or "as"
    sex              text    , -- 'm' - male, 'f' - female, 'x' - other
    yob              int     , -- year of birth
    bio              text    ,
 
    -- geo fields
    sczip            text    , -- the user's sex-country-zip code where the user last stayed. the format is sex + countrycode + originalzipcode. e.g. "mus94555"

    -- device fields
    service          text    , -- the push service of the user equipment. Allowed values are {"apn", "gcm", "mpn"}
    device           text    , -- the device token that identify an user equipment

    PRIMARY KEY (name)
) WITH COMPACTION = {'class': 'LeveledCompactionStrategy', 'enabled': 'true'};


/*
 * Write      : when a user MODIFIY a phone number
 * TTL        : none
 * Cardinality: equals the number of signedup users 
 * Workload   : both write-heavy and read-heavy
 *
 * @Discussion:
*/
CREATE TABLE IF NOT EXISTS username_by_phone (
    phone            bigint     ,
    name             list<text> , -- all the usernames have been used this phone

    PRIMARY KEY (phone)
);


/*
 * Write       : happens when a user occurs in a area (via POST user/location endpoint)
 * Read        : happens when a client GET user/nearby  
 * Workload    : both write-heavy and read-heavy, until the area is splited to smaller areas and then abandoned by winking.dynamic_area feature
 *
 * @Discussion : to make an area has a resaonable number of users, we need to track how many users in the user map. 
 *                   If the count is greater than the defined threshold, an area split will happen. TODO: consider move the counter to redis
 * 
 *               to handle the users leave/join an area, below rules need to be followed:
 *                   define a row identified by <area_id, hour> as the current slot, <area_id, hour + 1> as the next slot, and the rules for access will be:
 *                   1. All reads only happen on the current slot
 *                   2. All writes will happen on both the current slot and the next slot. Here write means inserting a <timestamp, user> pair into the slot's user map
 *                   3. As time goes, the next slot will become the new current slot, and a new next slot will be created
 *                   4. Any time we create a new slot, the 24-hours-old slot of the same area will be deleted to save disk space.
 */
CREATE TABLE IF NOT EXISTS user_by_area (
    areaid         text      , -- defined in winking.user_area
    hour           int       , -- the number of hours since joyy epoch (01 Jan 2015 00:00:00 GMT)
    userid         bigint    ,
    name           text      ,
    avatar         text      ,
    sex            text      ,
    yob            int       ,

    PRIMARY KEY ((areaid, hour), userid)
) WITH COMPACTION = {'class': 'LeveledCompactionStrategy', 'enabled': 'true'};


/*
 * Description: the table stores following relationship, which is used to get celebrity ids on pulling timeline
 * Query:     : SELECT followeeid FROM wink.following WHERE userid = $followerid AND isvip = true
 * Write      : when a user follows another user, a column is created
 *
 * @Discussion:
 */
CREATE TABLE IF NOT EXISTS following (
    userid            bigint , -- the follower's user id
    followeeid        bigint , -- the followee's user id
    name              text   ,
    avatar            text   ,
    sex               text   ,
    yob               int    ,

    PRIMARY KEY (userid, followeeid)
) WITH COMPACTION = {'class': 'LeveledCompactionStrategy', 'enabled': 'true'};


/*
 * Description: the table stores following relationship, which is used to get celebrity ids on pulling timeline
 * Query:     : SELECT followeeid FROM wink.following WHERE userid = $followerid AND isvip = true
 * Write      : when a user follows another user, a column is created when a follow relationship is created
 * TTL        : none
 * Workload   : read-heavy
 *
 * @Discussion:
 */
CREATE TABLE IF NOT EXISTS following_vip (
    userid            bigint  , -- the follower's user id
    vipid             bigint  , -- the vip followee's user id

    PRIMARY KEY (userid, vipid)
) WITH COMPACTION = {'class': 'LeveledCompactionStrategy', 'enabled': 'true'};

/*
 * Description: the table stores be followed relationship, which is used for an user to query his own follower information
 * Query:     : SELECT follower FROM wink.followed WHERE userid = $followeeid
 * Write      : when a user follows another user, a column is created when a follow relationship is created
 * TTL        : none
 * Workload   : write-heavy for celebrity followees 
 *
 * @Discussion:
 */
CREATE TABLE IF NOT EXISTS follower (
    userid         bigint     , -- the followee's user id
    followerid     bigint     , -- the follower's user id
    name           text       ,
    avatar         text       ,
    sex            text       ,
    yob            int        ,

    PRIMARY KEY (userid, followerid)
) WITH COMPACTION = {'class': 'LeveledCompactionStrategy', 'enabled': 'true'};
