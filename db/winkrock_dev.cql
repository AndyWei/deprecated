/*
 * winkrock_dev.cql
 * 
 * Copyright (c) 2015 Joyy Inc. All rights reserved.
 */
 

/*
 * keyspace
 * refer to http://docs.datastax.com/en/cql/3.3/cql/cql_using/useExampleCreatingKeyspace.html
 * @Discussion: only need run it once
*/
CREATE KEYSPACE IF NOT EXISTS winkrock WITH REPLICATION = {
    'class': 'SimpleStrategy',
    'replication_factor': '1'
 };

/*
 * DB users and premissions
 */
CREATE USER IF NOT EXISTS dev WITH PASSWORD 'password' NOSUPERUSER;

GRANT SELECT ON KEYSPACE winkrock TO dev;
GRANT MODIFY ON KEYSPACE winkrock TO dev;

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
    yrs              bigint  ,

    PRIMARY KEY (username)
) WITH COMPACTION = {'class': 'LeveledCompactionStrategy', 'enabled': 'true'};


/*
 *
 */
CREATE TABLE IF NOT EXISTS user_by_phone (
    phone            bigint ,
    username         text   ,
    userid           bigint ,
    yrs              bigint ,

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
 * Description: the table stores invite entities, which is for the "does an invite exist" query
 * Write      : when userA creates an invite edge to userB
 *
 * @Discussion:
 */
CREATE TABLE IF NOT EXISTS invite (
    fromid     bigint , -- from userid
    toid       bigint , -- to userid

    PRIMARY KEY (fromid, toid)
);

/*
 * Description: the table stores wink entities, which is for the "does a wink exist" query
 * Write      : when userA creates a wink edge to userB
 *
 * @Discussion:
 */
CREATE TABLE IF NOT EXISTS wink (
    fromid     bigint , -- from userid
    toid       bigint , -- to userid

    PRIMARY KEY (fromid, toid)
);

/*
 * Description: the table stores user inboxes of invites, which is for the "read invites" query
 * Write      : when userA want to create friendship with userB by invite, a row will be write to userB's invite inbox
 *
 * @Discussion:
 */
CREATE TABLE IF NOT EXISTS invite_inbox (
    userid       bigint , -- userid
    id           bigint , -- invite id
    fid          bigint , -- friend userid
    fname        text   , -- friend username
    fyrs         bigint , -- friend yrs, see YRS Encoding Rule. 
    phone        bigint , -- friend phone number

    PRIMARY KEY (userid, id)
);

/*
 * Description: the table stores user inboxes of winks, which is for the "read winks" query
 * Write      : when userA want to create friendship with userB by wink, a row will be write to userB's wink inbox
 *
 * @Discussion:
 */
CREATE TABLE IF NOT EXISTS wink_inbox (
    userid       bigint , -- userid
    id           bigint , -- wink id
    fid          bigint , -- friend userid
    fname        text   , -- friend username
    fyrs         bigint , -- friend yrs, see YRS Encoding Rule. 

    PRIMARY KEY (userid, id)
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
    area         text   , -- a man in US 94536 will have csz1 area "US19"
    month        int    , -- months in form of yymm
    userid       bigint ,
    username     text   ,
    yrs          bigint ,

    PRIMARY KEY ((area, month), userid)
) WITH CLUSTERING ORDER BY (userid DESC);


CREATE TABLE IF NOT EXISTS user_csz2 (
    area         text   , -- a man in US 94536 will have csz2 area "US194"
    month        int    , -- months in form of yymm
    userid       bigint ,
    username     text   ,
    yrs          bigint ,

    PRIMARY KEY ((area, month), userid)
) WITH CLUSTERING ORDER BY (userid DESC);


CREATE TABLE IF NOT EXISTS user_csz3 (
    area         text   , -- a man in US 94536 will have csz3 area code "US1945"
    month        int    , -- months in form of yymm
    userid       bigint ,
    username     text   ,
    yrs          bigint ,

    PRIMARY KEY ((area, month), userid)
) WITH CLUSTERING ORDER BY (userid DESC)
   AND COMPACTION = {'class': 'LeveledCompactionStrategy', 'enabled': 'true'};


CREATE TABLE IF NOT EXISTS user_csz4 (
    area         text   , -- a man in US 94536 will have csz4 area code "US19453"
    month        int    , -- months in form of yymm
    userid       bigint ,
    username     text   ,
    yrs          bigint ,

    PRIMARY KEY ((area, month), userid)
) WITH CLUSTERING ORDER BY (userid DESC)
   AND COMPACTION = {'class': 'LeveledCompactionStrategy', 'enabled': 'true'};


CREATE TABLE IF NOT EXISTS user_csz5 (
    area         text   , -- a man in US 94536 will have csz5 area code "US194536"
    month        int    , -- months in form of yymm
    userid       bigint ,
    username     text   ,
    yrs          bigint ,

    PRIMARY KEY ((area, month), userid)
) WITH CLUSTERING ORDER BY (userid DESC)
   AND COMPACTION = {'class': 'LeveledCompactionStrategy', 'enabled': 'true'};

/*
 * Feature: timeline
 * The table for the user query the posts from his friends
 * @Discussion: The user's own posts is in userline, while the comments of the timeline posts are in the commentline
 */
CREATE TABLE IF NOT EXISTS timeline (
    userid         bigint ,
    day            int    , -- the number of days in form of yymmdd
    postid         bigint ,
    ownerid        bigint ,
    url            text   ,
    caption        text   ,

    PRIMARY KEY ((userid, day), postid)
);

/*
 * Feature: comment
 * The table for the user query all the comments
 * @Discussion:
 */
CREATE TABLE IF NOT EXISTS commentline (
    userid         bigint ,
    commentid      bigint ,
    ownerid        bigint ,
    postid         bigint ,
    replytoid      bigint , -- the userid this comment replies to
    content        text   ,

    PRIMARY KEY (userid, commentid)
);

/*
 * Feature: userline
 * The table contains a user's own posts
 * @Discussion: The user's follower will read the posts from timeline
 */
CREATE TABLE IF NOT EXISTS userline (
    userid         bigint , -- owner userid
    month          int    , -- the number of month in form of yymm
    postid         bigint ,
    url            text   ,
    caption        text   ,

    PRIMARY KEY ((userid, month), postid)
);

/*
 * Test data
 */

-- user
INSERT INTO user (userid, username, deleted, phone, yrs) VALUES (114269549829816320, 'andyw', false, 14257850318, 130416641);
INSERT INTO user (userid, username, deleted, phone, yrs) VALUES (20, 'pingy', false, 14256287208, 130416640);

INSERT INTO user_by_name (username, userid, password, yrs) VALUES ('andyw', 114269549829816320, '$2a$10$.pJOlEZ/hMZRyw3CoFDHm.IBAV6nek6PWAtseFdgKIlDfDUVP23cG', 130416641);
INSERT INTO user_by_name (username, userid, password, yrs) VALUES ('pingy', 20, '$2a$10$.pJOlEZ/hMZRyw3CoFDHm.IBAV6nek6PWAtseFdgKIlDfDUVP23cG', 130416640);

INSERT INTO user_by_phone (phone, userid, username, yrs) VALUES (14257850318, 114269549829816320, 'andyw', 130416641);
INSERT INTO user_by_phone (phone, userid, username, yrs) VALUES (14256287208, 20, 'pingy', 130416640);

INSERT INTO user_csz1 (area, month, userid, username, yrs) VALUES ('US09', 1601, 1, 'user1', 130416640);
INSERT INTO user_csz1 (area, month, userid, username, yrs) VALUES ('US09', 1601, 2, 'user2', 130416640);
INSERT INTO user_csz1 (area, month, userid, username, yrs) VALUES ('US09', 1601, 3, 'user3', 130416640);
INSERT INTO user_csz1 (area, month, userid, username, yrs) VALUES ('US09', 1601, 4, 'user4', 130416640);
INSERT INTO user_csz1 (area, month, userid, username, yrs) VALUES ('US09', 1601, 5, 'user5', 130416640);
INSERT INTO user_csz1 (area, month, userid, username, yrs) VALUES ('US09', 1601, 6, 'user6', 130416640);
INSERT INTO user_csz1 (area, month, userid, username, yrs) VALUES ('US09', 1601, 7, 'user7', 130416640);
INSERT INTO user_csz1 (area, month, userid, username, yrs) VALUES ('US09', 1601, 8, 'user8', 130416640);
INSERT INTO user_csz1 (area, month, userid, username, yrs) VALUES ('US09', 1601, 9, 'user9', 130416640);
INSERT INTO user_csz1 (area, month, userid, username, yrs) VALUES ('US09', 1601, 10, 'user10', 130416640);
INSERT INTO user_csz1 (area, month, userid, username, yrs) VALUES ('US09', 1601, 11, 'user11', 130416640);
INSERT INTO user_csz1 (area, month, userid, username, yrs) VALUES ('US09', 1601, 12, 'user12', 130416640);
INSERT INTO user_csz1 (area, month, userid, username, yrs) VALUES ('US09', 1601, 13, 'user13', 130416640);
INSERT INTO user_csz1 (area, month, userid, username, yrs) VALUES ('US09', 1601, 14, 'user14', 130416640);
INSERT INTO user_csz1 (area, month, userid, username, yrs) VALUES ('US09', 1601, 15, 'user15', 130416640);
INSERT INTO user_csz1 (area, month, userid, username, yrs) VALUES ('US09', 1601, 16, 'user16', 130416640);
INSERT INTO user_csz1 (area, month, userid, username, yrs) VALUES ('US09', 1601, 17, 'user17', 130416640);
INSERT INTO user_csz1 (area, month, userid, username, yrs) VALUES ('US09', 1601, 18, 'user18', 130416640);
INSERT INTO user_csz1 (area, month, userid, username, yrs) VALUES ('US09', 1601, 19, 'user19', 130416640);
INSERT INTO user_csz1 (area, month, userid, username, yrs) VALUES ('US09', 1601, 20, 'pingy', 130416640);

