/*
 * post.cql
 * 
 * Copyright (c) 2015 Joyy Inc. All rights reserved.
 */

USE winkrock;

/*
 * Feature: timeline
 * The table for the user query the posts from his friends
 * @Discussion: The user's own posts is in userline, while the comments of the timeline posts are in the commentline
 */
CREATE TABLE IF NOT EXISTS timeline (
    userid         bigint ,
    day            int    , -- the number of days in form of yymmdd
    postid         bigint ,
    url            text   ,
    caption        text   ,

    PRIMARY KEY ((userid, day), postid)
) WITH COMPACTION = {'class': 'LeveledCompactionStrategy', 'enabled': 'true'};

/*
 * Feature: comment
 * The table for the user query all the comments
 * @Discussion:
 */
CREATE TABLE IF NOT EXISTS commentline (
    userid         bigint ,
    commentid      bigint ,
    postid         bigint ,
    replytoid      bigint , -- the userid this comment replies to
    content        text   ,

    PRIMARY KEY (userid, commentid)
) WITH COMPACTION = {'class': 'LeveledCompactionStrategy', 'enabled': 'true'};

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


