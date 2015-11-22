//
//  JYLocalDataManager.m
//  joyyios
//
//  Created by Ping Yang on 11/13/15.
//  Copyright © 2015 Joyy Inc. All rights reserved.
//

#import <FMDB/FMDB.h>
#import <Mantle/Mantle.h>

#import "JYComment.h"
#import "JYLocalDataManager.h"
#import "JYPost.h"
#import "MTLFMDBAdapter.h"

@interface JYLocalDataManager ()
@property (nonatomic) FMDatabaseQueue * dbQueue;
@end

NSString *const kDBName = @"/winkrock.db";
NSString *const kMinCommentIdKey = @"min_comment_id_in_db";
NSString *const kMaxCommentIdKey = @"max_comment_id_in_db";

static NSString *const CREATE_USER_TABLE_SQL =
@"CREATE TABLE IF NOT EXISTS user ( \
    id       INTEGER NOT NULL, \
    username TEXT    NOT NULL, \
    yrs      INTEGER NOT NULL, \
PRIMARY KEY(id)) ";

static NSString *const CREATE_POST_TABLE_SQL =
@"CREATE TABLE IF NOT EXISTS post ( \
    id      INTEGER NOT NULL, \
    ownerid INTEGER NOT NULL, \
    url     TEXT    NOT NULL, \
    caption TEXT    NOT NULL, \
PRIMARY KEY(id)) ";

static NSString *const CREATE_COMMENT_TABLE_SQL =
@"CREATE TABLE IF NOT EXISTS comment ( \
    id        INTEGER NOT NULL, \
    ownerid   INTEGER NOT NULL, \
    postid    INTEGER NOT NULL, \
    replytoid INTEGER NOT NULL, \
    content   TEXT    NOT NULL, \
PRIMARY KEY(id)) ";

static NSString *const CREATE_COMMENT_INDEX_SQL = @"CREATE INDEX IF NOT EXISTS postid_index ON comment(postid)";
static NSString *const SELECT_RANGE_SQL = @"SELECT * FROM %@ WHERE id > (?) AND id < (?) ORDER BY id DESC";
static NSString *const SELECT_KEY_SQL = @"SELECT * FROM %@ WHERE %@ = ? ORDER BY id ASC";


@implementation JYLocalDataManager

+ (JYLocalDataManager *)sharedInstance
{
    static JYLocalDataManager *_sharedInstance = nil;
    static dispatch_once_t done;

    dispatch_once(&done, ^{
        _sharedInstance = [JYLocalDataManager new];
    });

    return _sharedInstance;
}

- (instancetype)init
{
    return [self initDBWithName:kDBName];
}

- (instancetype)initDBWithName:(NSString *)dbName {
    self = [super init];
    if (self) {
        NSString *folderPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        NSString *dbPath = [folderPath stringByAppendingString:kDBName];
        if (_dbQueue) {
            [self close];
        }
        _dbQueue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    }
    return self;
}

- (void)start
{
    [self _executeUpdateSQL:CREATE_USER_TABLE_SQL];
    [self _executeUpdateSQL:CREATE_POST_TABLE_SQL];
    [self _executeUpdateSQL:CREATE_COMMENT_TABLE_SQL];
    [self _executeUpdateSQL:CREATE_COMMENT_INDEX_SQL];

    NSLog(@"LocalDataManager started");
}

- (void)close {
    [_dbQueue close];
    _dbQueue = nil;
}

- (void)saveJsonArray:(NSArray *)array ofClass:(Class)modelClass
{
    NSString *stmt = [MTLFMDBAdapter insertStatementForModelClass:modelClass];

    NSError *error = nil;
    for (NSDictionary *dict in array)
    {
        id obj = [MTLJSONAdapter modelOfClass:modelClass fromJSONDictionary:dict error:&error];
        if (error)
        {
            NSLog(@"Fail to decode object dict. modelClass = %@, dict = %@, error = %@", modelClass, dict, error);
            continue;
        }

        NSArray *params = [MTLFMDBAdapter columnValues:obj];
        [self _executeUpdate:stmt withArgumentsInArray:params];
    }
}

- (void)saveObjects:(NSArray *)objectList ofClass:(Class)modelClass
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{

        NSString *stmt = [MTLFMDBAdapter insertStatementForModelClass:modelClass];
        for (id obj in objectList)
        {
            NSArray *params = [MTLFMDBAdapter columnValues:obj];
            [self _executeUpdate:stmt withArgumentsInArray:params];
        }
    });
}

- (NSMutableArray *)selectPostsSinceId:(NSNumber *)minId beforeId:(NSNumber *)maxId
{
    NSString *sql = [NSString stringWithFormat:SELECT_RANGE_SQL, @"post"];
    NSMutableArray *result = [self _executeSelect:sql minId:minId maxId:maxId ofClass:JYPost.class];
    return result;
}

- (NSMutableArray *)selectCommentsOfPostId:(NSNumber *)postId
{
    NSString *sql = [NSString stringWithFormat:SELECT_KEY_SQL, @"comment", @"postid"];
    NSMutableArray *result = [self _executeSelect:sql keyId:postId ofClass: JYComment.class];
    return result;
}

- (void)setMinCommentIdInDB:(NSNumber *)minCommentIdInDB
{
    [[NSUserDefaults standardUserDefaults] setObject:minCommentIdInDB forKey:kMinCommentIdKey];
}

- (NSNumber *)minCommentIdInDB
{
    NSNumber *minId = [[NSUserDefaults standardUserDefaults] objectForKey:kMinCommentIdKey];
    if (!minId)
    {
        return [NSNumber numberWithUnsignedLongLong:LLONG_MAX]; // note it's not ULLONG_MAX as the DB is in Java
    }
    return minId;
}

- (void)setMaxCommentIdInDB:(NSNumber *)maxCommentIdInDB
{
    [[NSUserDefaults standardUserDefaults] setObject:maxCommentIdInDB forKey:kMaxCommentIdKey];
}

- (NSNumber *)maxCommentIdInDB
{
    NSNumber *maxId = [[NSUserDefaults standardUserDefaults] objectForKey:kMinCommentIdKey];
    if (!maxId)
    {
        return 0;
    }
    return maxId;
}

- (NSMutableArray *)_executeSelect:(NSString *)sql minId:(NSNumber *)minId maxId:(NSNumber *)maxId ofClass:(Class)modelClass
{
    __block NSMutableArray * result = [NSMutableArray array];
    [_dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet * rs = [db executeQuery:sql, minId, maxId];
        while ([rs next]) {
            NSError *error = nil;
            id item = [MTLFMDBAdapter modelOfClass:modelClass fromFMResultSet:rs error:&error];
            if (!error)
            {
                [result addObject:item];
            }
        }
        [rs close];
    }];

    return result;
}

- (NSMutableArray *)_executeSelect:(NSString *)sql keyId:(NSNumber *)keyId ofClass:(Class)modelClass
{
    __block NSMutableArray * result = [NSMutableArray array];
    [_dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet * rs = [db executeQuery:sql, keyId];
        while ([rs next]) {
            NSError *error = nil;
            id item = [MTLFMDBAdapter modelOfClass:modelClass fromFMResultSet:rs error:&error];
            if (!error)
            {
                [result addObject:item];
            }
        }
        [rs close];
    }];

    return result;
}

- (void)_executeUpdateSQL:(NSString *)sql
{
    __block BOOL result;
    [_dbQueue inDatabase:^(FMDatabase *db) {
        result = [db executeUpdate:sql];
    }];

    if (!result)
    {
        NSLog(@"ERROR, failed to execute update sql: %@", sql);
    }
}

- (void)_executeUpdate:(NSString *)stmt withArgumentsInArray:(NSArray *)params
{
    __block BOOL result;
    [_dbQueue inDatabase:^(FMDatabase *db) {
        result = [db executeUpdate:stmt withArgumentsInArray:params];
    }];

    if (!result)
    {
        NSLog(@"ERROR, failed to update table with sql = %@ and params = %@", stmt, params);
    }
}
@end

