//
//  JYLocalDataManager.h
//  joyyios
//
//  Created by Ping Yang on 11/13/15.
//  Copyright © 2015 Joyy Inc. All rights reserved.
//

@class JYPost;

@interface JYLocalDataManager : NSObject

+ (JYLocalDataManager *)sharedInstance;
- (void)start;
- (void)insertObjects:(NSArray *)objectList ofClass:(Class)modelClass;
- (void)insertObject:(id)object ofClass:(Class)modelClass;
- (void)updateObjects:(NSArray *)objectList ofClass:(Class)modelClass;
- (void)updateObject:(id)object ofClass:(Class)modelClass;
- (void)deleteObject:(id)object ofClass:(Class)modelClass;
- (JYPost *)selectPostWithId:(NSNumber *)postId;
- (NSMutableArray *)selectPostsSinceId:(NSNumber *)minId beforeId:(NSNumber *)maxId;
- (NSMutableArray *)selectCommentsOfPostId:(NSNumber *)postId;
- (NSMutableArray *)selectFriends;
- (NSSet *)selectInvitedUsers;
- (NSSet *)selectHitUsers;

- (void)receivedCommentList:(NSArray *)commentList;

@property (nonatomic) NSNumber *minCommentIdInDB;
@property (nonatomic) NSNumber *maxCommentIdInDB;

@end
