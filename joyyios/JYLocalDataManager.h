//
//  JYLocalDataManager.h
//  joyyios
//
//  Created by Ping Yang on 11/13/15.
//  Copyright © 2015 Joyy Inc. All rights reserved.
//

#import "JYUser.h"

@interface JYLocalDataManager : NSObject

+ (JYLocalDataManager *)sharedInstance;
- (void)start;
- (void)insertObjects:(NSArray *)objectList ofClass:(Class)modelClass;
- (void)insertObject:(id)object ofClass:(Class)modelClass;
- (void)updateObjects:(NSArray *)objectList ofClass:(Class)modelClass;
- (void)updateObject:(id)object ofClass:(Class)modelClass;

- (NSMutableArray *)selectPostsSinceId:(NSNumber *)minId beforeId:(NSNumber *)maxId;
- (NSMutableArray *)selectCommentsOfPostId:(NSNumber *)postId;
- (NSMutableArray *)selectFriends;

@property (nonatomic) NSNumber *minCommentIdInDB;
@property (nonatomic) NSNumber *maxCommentIdInDB;

@end
