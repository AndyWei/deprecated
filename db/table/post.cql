/*
 * post.cql
 * 
 * Copyright (c) 2015 Joyy Inc. All rights reserved.
 */


/*
 * Feature: Activity
 * The table to store the post objects
 * @Discussion: The user own posts is in userline_per_month
 */
CREATE TABLE IF NOT EXISTS wink.post (
    id             bigint ,
    brief          text   ,
    url            text   ,
    userid         bigint ,  -- the owner user id
    like_count     int    ,
    comment_count  int    ,

    PRIMARY KEY (id)
) WITH COMPACTION = {'class': 'LeveledCompactionStrategy', 'enabled': 'true'};


/*
 * Feature: timeline
 * The table for the user query the posts from his followees
 * @Discussion: The user own posts is in userline_per_month
 */
CREATE TABLE IF NOT EXISTS wink.timeline (
    userid         bigint ,
    day            int    , -- the number of days since joyy epoch
    postid         bigint ,
    brief          text   ,
    url            text   ,

    PRIMARY KEY ((userid, day), postid)
) WITH COMPACTION = {'class': 'LeveledCompactionStrategy', 'enabled': 'true'};


/*
 * Feature: userline
 * The table for the user query his own posts
 * @Discussion: The user's follower will read the posts from timeline_per_day
 */
CREATE TABLE IF NOT EXISTS wink.userline (
    userid         bigint , -- owner userid
    day            int    , -- the number of days since joyy epoch
    postid         bigint ,
    brief          text   ,
    url            text   ,     

    PRIMARY KEY ((userid, month), postid)
) WITH COMPACTION = {'class': 'LeveledCompactionStrategy', 'enabled': 'true'};


/*
 * Feature: comment
 * The table for the user query the comments of a post
 * @Discussion:
 */
CREATE TABLE IF NOT EXISTS wink.comment (
    postid         bigint ,
    commentid      bigint ,
    content        text   ,

    PRIMARY KEY (postid, commentid)
) WITH COMPACTION = {'class': 'LeveledCompactionStrategy', 'enabled': 'true'};


/*
 * Feature: like
 * The table for the user query the comments of a post
 * @Discussion:
 */
CREATE TABLE IF NOT EXISTS wink.like (
    postid         bigint ,
    userid         bigint , -- the user who liked this post

    PRIMARY KEY (postid, userid)
) WITH COMPACTION = {'class': 'LeveledCompactionStrategy', 'enabled': 'true'};

