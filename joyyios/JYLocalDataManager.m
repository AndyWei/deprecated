//
//  JYLocalDataManager.m
//  joyyios
//
//  Created by Ping Yang on 11/13/15.
//  Copyright © 2015 Joyy Inc. All rights reserved.
//

#import <FMDB/FMDB.h>
#import <Mantle/Mantle.h>

#import "JYLocalDataManager.h"
#import "MTLFMDBAdapter.h"

@interface JYLocalDataManager ()
@property (nonatomic) FMDatabaseQueue *dbQueue;
@end

NSString *const kDBName = @"/winkrock.db";

static NSString *const CREATE_USER_TABLE_SQL =
@"CREATE TABLE IF NOT EXISTS user ( \
    id       INTEGER NOT NULL, \
    username TEXT    NOT NULL, \
    yrs      INTEGER NOT NULL, \
    hit      INTEGER NOT NULL, \
    invited  INTEGER NOT NULL, \
    phone    INTEGER         , \
    bio      TEXT            , \
PRIMARY KEY(id)) ";

static NSString *const CREATE_FRIEND_TABLE_SQL =
@"CREATE TABLE IF NOT EXISTS friend ( \
    id       INTEGER NOT NULL, \
    username TEXT    NOT NULL, \
    yrs      INTEGER NOT NULL, \
    phone    INTEGER         , \
    bio      TEXT            , \
PRIMARY KEY(id)) ";

static NSString *const CREATE_INVITE_TABLE_SQL =
@"CREATE TABLE IF NOT EXISTS invite ( \
    id       INTEGER NOT NULL, \
    userid   INTEGER NOT NULL, \
    username TEXT    NOT NULL, \
    yrs      INTEGER NOT NULL, \
    phone    INTEGER NOT NULL, \
PRIMARY KEY(id)) ";

static NSString *const CREATE_WINK_TABLE_SQL =
@"CREATE TABLE IF NOT EXISTS wink ( \
    id       INTEGER NOT NULL, \
    userid   INTEGER NOT NULL, \
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

static NSString *const CREATE_MESSAGE_TABLE_SQL =
@"CREATE TABLE IF NOT EXISTS message ( \
    id         INTEGER NOT NULL, \
    userid     INTEGER NOT NULL, \
    peerid     INTEGER NOT NULL, \
    isoutgoing INTEGER NOT NULL, \
    body       TEXT    NOT NULL, \
PRIMARY KEY(id)) ";

static NSString *const CREATE_SESSION_TABLE_SQL =
@"CREATE TABLE IF NOT EXISTS session ( \
    id         INTEGER NOT NULL, \
    userid     INTEGER NOT NULL, \
    isoutgoing INTEGER NOT NULL, \
    hasread    INTEGER NOT NULL, \
    timestamp  INTEGER NOT NULL, \
    body       TEXT    NOT NULL, \
PRIMARY KEY(id)) ";

static NSString *const CREATE_COMMENT_INDEX_SQL = @"CREATE INDEX IF NOT EXISTS postid_index ON comment(postid)";
static NSString *const CREATE_MESSAGE_PEERID_INDEX_SQL = @"CREATE INDEX IF NOT EXISTS peerid_index ON message(peerid)";
static NSString *const CREATE_SESSION_USERID_INDEX_SQL = @"CREATE INDEX IF NOT EXISTS userid_index ON session(userid)";
static NSString *const DELETE_CONDITION_SQL = @"DELETE FROM %@ WHERE %@";
static NSString *const SELECT_RANGE_SQL = @"SELECT * FROM %@ WHERE id > (?) AND id < (?) ORDER BY id DESC";
static NSString *const SELECT_CONDITION_SQL = @"SELECT * FROM %@ WHERE (%@) ORDER BY id %@";
static NSString *const SELECT_LIMIT_SQL = @"SELECT * FROM %@ ORDER BY id %@ LIMIT %u";
static NSString *const SELECT_KEY_SQL = @"SELECT * FROM %@ WHERE %@ = ? ORDER BY id ASC";
static NSString *const SELECT_KEY_WITH_ORDER_SQL = @"SELECT * FROM %@ WHERE %@ = ? ORDER BY %@";
static NSString *const SELECT_ALL_SQL = @"SELECT * FROM %@ ORDER BY id ASC";
static NSString *const SELECT_MIN_ID_SQL = @"SELECT * FROM %@ ORDER BY id ASC LIMIT 1";
static NSString *const SELECT_MAX_ID_SQL = @"SELECT * FROM %@ ORDER BY id DESC LIMIT 1";

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
    [self _executeUpdateSQL:CREATE_FRIEND_TABLE_SQL];
    [self _executeUpdateSQL:CREATE_INVITE_TABLE_SQL];
    [self _executeUpdateSQL:CREATE_WINK_TABLE_SQL];
    [self _executeUpdateSQL:CREATE_POST_TABLE_SQL];

    [self _executeUpdateSQL:CREATE_COMMENT_TABLE_SQL];
    [self _executeUpdateSQL:CREATE_COMMENT_INDEX_SQL];

    [self _executeUpdateSQL:CREATE_MESSAGE_TABLE_SQL];
    [self _executeUpdateSQL:CREATE_MESSAGE_PEERID_INDEX_SQL];

    [self _executeUpdateSQL:CREATE_SESSION_TABLE_SQL];
    [self _executeUpdateSQL:CREATE_SESSION_USERID_INDEX_SQL];

    NSLog(@"LocalDataManager started");
}

- (void)close {
    [_dbQueue close];
    _dbQueue = nil;
}

- (void)insertObjects:(NSArray *)objectList ofClass:(Class)modelClass
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

        NSString *stmt = [MTLFMDBAdapter insertStatementForModelClass:modelClass];
        for (id obj in objectList)
        {
            NSArray *params = [MTLFMDBAdapter columnValues:obj];
            [self _executeUpdate:stmt withArgumentsInArray:params];
        }
    });
}

- (void)insertObject:(id)object ofClass:(Class)modelClass
{
    [self insertObjects:@[object] ofClass:modelClass];
}

- (void)updateObjects:(NSArray *)objectList ofClass:(Class)modelClass
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

        NSString *stmt = [MTLFMDBAdapter updateStatementForModelClass:modelClass];
        for (id obj in objectList)
        {
            NSMutableArray *params = [NSMutableArray arrayWithArray:[MTLFMDBAdapter columnValues:obj]];
            [params addObjectsFromArray:[MTLFMDBAdapter primaryKeysValues:obj]];
            [self _executeUpdate:stmt withArgumentsInArray:params];
        }
    });
}

- (void)updateObject:(id)object ofClass:(Class)modelClass
{
    [self updateObjects:@[object] ofClass:modelClass];
}

- (void)deleteObject:(id)object ofClass:(Class)modelClass
{
    if(![modelClass conformsToProtocol:@protocol(MTLFMDBSerializing)])
    {
        return;
    }

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

        NSString *stmt = [MTLFMDBAdapter deleteStatementForModelClass:modelClass];
        NSArray *params = [MTLFMDBAdapter primaryKeysValues:object];
        [self _executeUpdate:stmt withArgumentsInArray:params];
    });
}

- (void)deleteObjectsOfClass:(Class)modelClass withCondition:(NSString *)condition
{
    if(![modelClass conformsToProtocol:@protocol(MTLFMDBSerializing)])
    {
        return;
    }

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

        NSString *sql = [NSString stringWithFormat:DELETE_CONDITION_SQL, [modelClass FMDBTableName], condition];
        [self _executeUpdateSQL:sql];
    });
}

- (NSMutableArray *)selectObjectsOfClass:(Class)modelClass
{
    if(![modelClass conformsToProtocol:@protocol(MTLFMDBSerializing)])
    {
        return [NSMutableArray new];
    }

    NSString *sql = [NSString stringWithFormat:SELECT_ALL_SQL, [modelClass FMDBTableName]];
    NSMutableArray *result = [self _executeSelect:sql ofClass:modelClass];
    return result;
}

- (NSMutableArray *)selectObjectsOfClass:(Class)modelClass limit:(uint32_t)limit sort:(NSString *)sort
{
    if(![modelClass conformsToProtocol:@protocol(MTLFMDBSerializing)])
    {
        return [NSMutableArray new];
    }

    NSString *sql = [NSString stringWithFormat:SELECT_LIMIT_SQL, [modelClass FMDBTableName], sort, limit];
    NSMutableArray *result = [self _executeSelect:sql ofClass:modelClass];
    return result;
}

- (NSMutableArray *)selectObjectsOfClass:(Class)modelClass withCondition:(NSString *)condition sort:(NSString *)sort
{
    if(![modelClass conformsToProtocol:@protocol(MTLFMDBSerializing)])
    {
        return [NSMutableArray new];
    }

    NSString *sql = [NSString stringWithFormat:SELECT_CONDITION_SQL, [modelClass FMDBTableName], condition, sort];
    NSMutableArray *result = [self _executeSelect:sql ofClass:modelClass];
    return result;
}

- (NSMutableArray *)selectObjectsOfClass:(Class)modelClass sinceId:(NSNumber *)minId beforeId:(NSNumber *)maxId
{
    if(![modelClass conformsToProtocol:@protocol(MTLFMDBSerializing)])
    {
        return [NSMutableArray new];
    }

    NSString *sql = [NSString stringWithFormat:SELECT_RANGE_SQL, [modelClass FMDBTableName]];
    NSMutableArray *result = [self _executeSelect:sql minId:minId maxId:maxId ofClass:modelClass];
    return result;
}

- (NSMutableArray *)selectObjectsOfClass:(Class)modelClass withProperty:(NSString *)property equals:(NSNumber *)value
{
    NSString *sql = [NSString stringWithFormat:SELECT_KEY_SQL, [modelClass FMDBTableName], property];
    NSMutableArray *result = [self _executeSelect:sql withId:value ofClass:modelClass];
    return result;
}

- (NSMutableArray *)selectObjectsOfClass:(Class)modelClass withProperty:(NSString *)property equals:(NSNumber *)value orderBy:(NSString *)orderBy
{
    NSString *sql = [NSString stringWithFormat:SELECT_KEY_WITH_ORDER_SQL, [modelClass FMDBTableName], property, orderBy];
    NSMutableArray *result = [self _executeSelect:sql withId:value ofClass:modelClass];
    return result;
}

- (id)minIdObjectOfOfClass:(Class)modelClass
{
    NSString *sql = [NSString stringWithFormat:SELECT_MIN_ID_SQL, [modelClass FMDBTableName]];
    return [self selectOneObjectOfOfClass:modelClass withSql:sql];
}

- (id)maxIdObjectOfOfClass:(Class)modelClass
{
    NSString *sql = [NSString stringWithFormat:SELECT_MAX_ID_SQL, [modelClass FMDBTableName]];
    return [self selectOneObjectOfOfClass:modelClass withSql:sql];
}

- (id)selectOneObjectOfOfClass:(Class)modelClass withSql:(NSString *)sql
{
    if(![modelClass conformsToProtocol:@protocol(MTLFMDBSerializing)])
    {
        return nil;
    }

    NSMutableArray *result = [self _executeSelect:sql ofClass:modelClass];
    if ([result count] == 0)
    {
        return nil;
    }
    return result[0];
}

- (id)selectObjectOfClass:(Class)modelClass withId:(NSNumber *)objId
{
    if(![modelClass conformsToProtocol:@protocol(MTLFMDBSerializing)])
    {
        return nil;
    }

    NSString *sql = [NSString stringWithFormat:SELECT_KEY_SQL, [modelClass FMDBTableName], [modelClass FMDBPrimaryKeys][0]];
    NSMutableArray *result = [self _executeSelect:sql withId:objId ofClass: modelClass];

    if ([result count] == 0)
    {
        return nil;
    }
    return result[0];
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

- (NSMutableArray *)_executeSelect:(NSString *)sql withId:(NSNumber *)objId ofClass:(Class)modelClass
{
    __block NSMutableArray * result = [NSMutableArray array];
    [_dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet * rs = [db executeQuery:sql, objId];
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

- (NSMutableArray *)_executeSelect:(NSString *)sql ofClass:(Class)modelClass
{
    __block NSMutableArray * result = [NSMutableArray array];
    [_dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet * rs = [db executeQuery:sql];
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

