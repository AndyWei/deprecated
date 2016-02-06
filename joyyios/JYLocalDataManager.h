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
- (void)insertObjects:(NSArray *)objectList ofClass:(Class)modelClass;
- (void)insertObject:(id)object ofClass:(Class)modelClass;
- (void)updateObjects:(NSArray *)objectList ofClass:(Class)modelClass;
- (void)updateObject:(id)object ofClass:(Class)modelClass;
- (void)deleteObject:(id)object ofClass:(Class)modelClass;
- (void)deleteObjectsOfClass:(Class)modelClass withCondition:(NSString *)condition;

- (id)selectObjectOfClass:(Class)modelClass withId:(NSNumber *)objId;
- (id)minIdObjectOfOfClass:(Class)modelClass;
- (id)maxIdObjectOfOfClass:(Class)modelClass;
- (id)maxIdObjectOfOfClass:(Class)modelClass withCondition:(NSString *)condition;

- (NSMutableArray *)selectObjectsOfClass:(Class)modelClass;
- (NSMutableArray *)selectObjectsOfClass:(Class)modelClass limit:(uint32_t)limit sort:(NSString *)sort;
- (NSMutableArray *)selectObjectsOfClass:(Class)modelClass withCondition:(NSString *)condition sort:(NSString *)sort;
- (NSMutableArray *)selectObjectsOfClass:(Class)modelClass sinceId:(NSNumber *)minId beforeId:(NSNumber *)maxId;
- (NSMutableArray *)selectObjectsOfClass:(Class)modelClass withProperty:(NSString *)property equals:(NSNumber *)value;
- (NSMutableArray *)selectObjectsOfClass:(Class)modelClass withProperty:(NSString *)property equals:(NSNumber *)value orderBy:(NSString *)orderBy;

@end
