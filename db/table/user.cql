/*
 * user.cql
 * 
 * Copyright (c) 2015 Joyy Inc. All rights reserved.
 */

USE winkrock;

/*
 * YRS Encoding Rule
 * yrs has 64 bits, 16 bits reserved, 16 bits of primary photo version, 16 bits of yob, 8 bits of region and 8 bits of sex, i.e. RRRRvvvvyyyyrrss
 * -- RRRR: reserved
 * -- vvvv: primary photo version
 * -- yyyy: year of birth
 * -- rr: the region where user's avatar photo stored. 0: North America, 1: Asia, 2: Europe
 * -- ss: user's sex.  0 - female, 1 - male, 2 - other
 */

/*
 * Description: main user table
 * Write      : when a user sign up, a row is created
 * TTL        : none
 * Cardinality: equals the number of signedup users 
 * Workload   : low
 *
 * @Discussion:
 */
CREATE TABLE IF NOT EXISTS user (
    userid           bigint  ,
    username         text    , -- only the last used username will be kept
    deleted          boolean , -- set to true only if the user deleted the account 

    -- profile fields updated in post profile
    phone            bigint  , -- phone number in E.164 format, but the leading '+' has been dropped
    yrs              bigint  , -- see YRS Encoding Rule 
    bio              text    ,

    PRIMARY KEY (userid)
) WITH COMPACTION = {'class': 'LeveledCompactionStrategy', 'enabled': 'true'};


/*
 * Description: user device table
 *
 * @Discussion:
 */
CREATE TABLE IF NOT EXISTS user_device (
    userid           bigint  ,
    pns              int     , -- the push notification service of the user device. Allowed values are: 1 - APNS, 2 - GCM, 3 - MPN
    dtoken           text    , -- the string that identify a user equipment. On iOS it is called device token, while on Android it is called registration ID
    arn              text    , -- the AWS SNS client endpoint ARN

    PRIMARY KEY (userid)
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
    username         text    ,
    userid           bigint  ,
    password         text    , -- bcrypt hashed password, it always 60 bytes long, however text makes it flexible

    PRIMARY KEY (username)
) WITH COMPACTION = {'class': 'LeveledCompactionStrategy', 'enabled': 'true'};


/*
 *
 */
CREATE TABLE IF NOT EXISTS user_by_phone (
    phone        bigint ,
    username     text   ,
    userid       bigint ,
    yrs          bigint ,

    PRIMARY KEY (phone)
) WITH COMPACTION = {'class': 'LeveledCompactionStrategy', 'enabled': 'true'};

/*
 *
 */
CREATE TABLE IF NOT EXISTS code_by_phone (
    phone            bigint ,
    code             int    ,

    PRIMARY KEY (phone)
);

/*
 * Description: the table stores friendship invite
 * Write      : when userA want to create friendship with userB, a row will be write to userB's invite partition
 *
 * @Discussion:
 */
CREATE TABLE IF NOT EXISTS invite (
    userid       bigint , -- userid
    fid          bigint , -- friend userid
    fname        text   , -- friend username
    fyrs         bigint , -- friend yrs, see YRS Encoding Rule. 

    PRIMARY KEY (userid, fid)
);

/*
 * Description: the table stores friendship wink invite
 * Write      : when userA want to create friendship with userB, a row will be write to userB's wink partition
 *
 * @Discussion:
 */
CREATE TABLE IF NOT EXISTS wink (
    userid       bigint , -- userid
    fid          bigint , -- friend userid
    fname        text   , -- friend username
    fyrs         bigint , -- friend yrs, see YRS Encoding Rule. 

    PRIMARY KEY (userid, fid)
);

/*
 * Description: the table stores friendship, which is used to get the friend timeline ids for pushing new post
 * Query:     : all_my_friends = SELECT fid FROM friendship WHERE uid = $my_userid
 * Write      : when 2 users become friends, 2 columns will be created
 *
 * @Discussion:
 */
CREATE TABLE IF NOT EXISTS friend (
    userid       bigint , -- userid
    fid          bigint , -- friend userid
    fname        text   , -- friend username
    fyrs         bigint , -- friend yrs, see YRS Encoding Rule. 

    PRIMARY KEY (userid, fid)
) WITH COMPACTION = {'class': 'LeveledCompactionStrategy', 'enabled': 'true'};

/*
 * Write       : happens when a user occurs in a area (via POST user/occur endpoint)
 * Read        : happens when a client GET user/nearby  
 * Workload    : both write-heavy and read-heavy
 *
 * @Discussion : to handle the users leave/join an area, below rules need to be followed:
 *                   define a row identified by <area, month> as the current slot, <areaid, month + 1> as the next slot, and the rules for access will be:
 *                   1. All reads only happen on the current slot
 *                   2. All writes happen on the current slot, and if it's the last day of the month, then also write into the next slot.
 *                   3. As time goes, the next slot will become the new current slot, and a new next slot will be created
 *                   4. The old slots will be deleted to save disk space.
 */
CREATE TABLE IF NOT EXISTS user_csz1 (
    area         text   , -- a man in US 94536 will have csz1 area "US09"
    month        int    , -- months in form of yymm
    userid       bigint ,
    username     text   ,
    yrs          bigint ,

    PRIMARY KEY ((area, month), userid)
) WITH CLUSTERING ORDER BY (userid DESC);


CREATE TABLE IF NOT EXISTS user_csz2 (
    area         text   , -- a man in US 94536 will have csz2 area "US094"
    month        int    , -- months in form of yymm
    userid       bigint ,
    username     text   ,
    yrs          bigint ,

    PRIMARY KEY ((area, month), userid)
) WITH CLUSTERING ORDER BY (userid DESC);


CREATE TABLE IF NOT EXISTS user_csz3 (
    area         text   , -- a man in US 94536 will have csz3 area code "US0945"
    month        int    , -- months in form of yymm
    userid       bigint ,
    username     text   ,
    yrs          bigint ,

    PRIMARY KEY ((area, month), userid)
) WITH CLUSTERING ORDER BY (userid DESC)
   AND COMPACTION = {'class': 'LeveledCompactionStrategy', 'enabled': 'true'};


CREATE TABLE IF NOT EXISTS user_csz4 (
    area         text   , -- a man in US 94536 will have csz4 area code "US09453"
    month        int    , -- months in form of yymm
    userid       bigint ,
    username     text   ,
    yrs          bigint ,

    PRIMARY KEY ((area, month), userid)
) WITH CLUSTERING ORDER BY (userid DESC)
   AND COMPACTION = {'class': 'LeveledCompactionStrategy', 'enabled': 'true'};


CREATE TABLE IF NOT EXISTS user_csz5 (
    area         text   , -- a man in US 94536 will have csz5 area code "US094536"
    month        int    , -- months in form of yymm
    userid       bigint ,
    username     text   ,
    yrs          bigint ,

    PRIMARY KEY ((area, month), userid)
) WITH CLUSTERING ORDER BY (userid DESC)
   AND COMPACTION = {'class': 'LeveledCompactionStrategy', 'enabled': 'true'};

