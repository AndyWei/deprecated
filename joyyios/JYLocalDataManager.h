//
//  JYLocalDataManager.h
//  joyyios
//
//  Created by Ping Yang on 11/13/15.
//  Copyright © 2015 Joyy Inc. All rights reserved.
//

@interface JYLocalDataManager : NSObject

+ (JYLocalDataManager *)sharedInstance;
- (void)start;
- (void)saveJsonArray:(NSArray *)array ofClass:(Class)modelClass;
- (void)saveObjects:(NSArray *)objectList ofClass:(Class)modelClass;

- (NSMutableArray *)selectPostsSinceId:(uint64_t)minId beforeId:(uint64_t)maxId;
- (NSMutableArray *)selectCommentsOfPostId:(uint64_t)postId;

@property (nonatomic) uint64_t minCommentIdInDB;
@property (nonatomic) uint64_t maxCommentIdInDB;

@end
