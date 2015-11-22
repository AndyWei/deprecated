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

- (NSMutableArray *)selectPostsSinceId:(NSNumber *)minId beforeId:(NSNumber *)maxId;
- (NSMutableArray *)selectCommentsOfPostId:(NSNumber *)postId;

@property (nonatomic) NSNumber *minCommentIdInDB;
@property (nonatomic) NSNumber *maxCommentIdInDB;

@end
