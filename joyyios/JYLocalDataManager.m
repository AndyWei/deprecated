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
#import "JYPost.h"
#import "MTLFMDBAdapter.h"

@interface JYLocalDataManager ()
@property (nonatomic) FMDatabaseQueue * dbQueue;
@end

NSString *const kDBName = @"winkrock.db";

static NSString *const CREATE_USER_TABLE_SQL =
@"CREATE TABLE IF NOT EXISTS post ( \
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
    [self _createTableWithSQL:CREATE_USER_TABLE_SQL];
    [self _createTableWithSQL:CREATE_POST_TABLE_SQL];
    [self _createTableWithSQL:CREATE_COMMENT_TABLE_SQL];

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

- (void)_createTableWithSQL:(NSString *)sql
{
    __block BOOL result;
    [_dbQueue inDatabase:^(FMDatabase *db) {
        result = [db executeUpdate:sql];
    }];

    if (!result)
    {
        NSLog(@"ERROR, failed to create table with sql: %@", sql);
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
        NSLog(@"ERROR, failed to update table with sql: %@", stmt);
    }
}
@end

