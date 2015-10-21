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
 * Workload   : low
 *
 * @Discussion:
 */
CREATE TABLE IF NOT EXISTS user (
    id               bigint  ,
    username         text    , -- only the last used username will be kept
    deleted          boolean , -- set to true only if the user deleted the account 

    -- profile fields updated in post profile
    phone            bigint  , -- phone number in E.164 format, but the leading '+' has been dropped
    region           int     , -- the avatar photo stored region of the friend. Currently 3 values are available: 0: North America, 1: Asia, 2: Europe. 
    sex              int     , -- 0: female, 1: male, 2: other
    yob              int     , -- year of birth
    bio              text    ,
 
    -- device fields
    service          text    , -- the push service of the user equipment. Allowed values are {"apn", "gcm", "mpn"}
    device           text    , -- the device token that identify an user equipment

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
    username         text    ,
    id               bigint  ,
    password         text    , -- bcrypt hashed password, it always 60 bytes long, however text makes it flexible

    PRIMARY KEY (username)
) WITH COMPACTION = {'class': 'LeveledCompactionStrategy', 'enabled': 'true'};


/*
 * Write      : when a user MODIFIY a phone number
 * TTL        : none
 * Cardinality: equals the number of signedup users 
 * Workload   : both write-heavy and read-heavy
 *
 * @Discussion:
*/
CREATE TABLE IF NOT EXISTS user_by_phone (
    phone            bigint     ,
    username         text       ,
    id               bigint     ,

    PRIMARY KEY (phone)
) WITH COMPACTION = {'class': 'LeveledCompactionStrategy', 'enabled': 'true'};


/*
 * Write       : happens when a user occurs in a area (via POST user/location endpoint)
 * Read        : happens when a client GET user/nearby  
 * Workload    : both write-heavy and read-heavy, until the area is splited to smaller areas and then abandoned by winking.dynamic_area feature
 *
 * @Discussion : to make an area has a resaonable number of users, we need to track how many users in the user map. 
 *                   If the count is greater than the defined threshold, an area split will happen. TODO: consider move the counter to redis
 * 
 *               to handle the users leave/join an area, below rules need to be followed:
 *                   define a row identified by <areaid, hour> as the current slot, <areaid, hour + 1> as the next slot, and the rules for access will be:
 *                   1. All reads only happen on the current slot
 *                   2. All writes will happen on both the current slot and the next slot. Here write means inserting a <timestamp, user> pair into the slot's user map
 *                   3. As time goes, the next slot will become the new current slot, and a new next slot will be created
 *                   4. Any time we create a new slot, the 24-hours-old slot of the same area will be deleted to save disk space.
 */
CREATE TABLE IF NOT EXISTS user_by_area (
    areaid       text   , -- defined in area.cql area
    hour         int    , -- the number of hours since joyy epoch (01 Jan 2015 00:00:00 GMT)
    userid       bigint ,
    username     text   ,
    region       int    ,
    sex          int    , -- 0: female, 1: male, 2: other
    yob          int    , -- year of birth
    bio          text   ,

    PRIMARY KEY ((areaid, hour), userid)
) WITH CLUSTERING ORDER BY (userid DESC)
   AND COMPACTION = {'class': 'LeveledCompactionStrategy', 'enabled': 'true'};


/*
 * Description: the table stores friendship, which is used to get the friend timeline ids for pushing new post
 * Query:     : all_my_friends = SELECT fid FROM friendship WHERE uid = $my_userid
 * Write      : when 2 users become friends, 2 columns will be created
 *
 * @Discussion:
 */
CREATE TABLE IF NOT EXISTS friendship (
    userid       bigint , -- userid
    fid          bigint , -- friend userid
    fname        text   , -- friend username
    fregion      int    , -- the region where friend's avatar photo stored. Currently 3 values are available: 0: North America, 1: Asia, 2: Europe. 

    PRIMARY KEY (userid, fid)
) WITH COMPACTION = {'class': 'LeveledCompactionStrategy', 'enabled': 'true'};

