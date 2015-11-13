//
//  JYLocalDataManager.m
//  joyyios
//
//  Created by Ping Yang on 11/13/15.
//  Copyright © 2015 Joyy Inc. All rights reserved.
//

#import <FMDB/FMDB.h>

#import "JYLocalDataManager.h"

@interface JYLocalDataManager ()
@property (nonatomic) FMDatabase *db;
@end

NSString *const kDBName = @"winkrock.db";

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
    self = [super init];
    if (self)
    {
        NSString *folderPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        NSString *dbPath = [folderPath stringByAppendingString:kDBName];
        self.db = [FMDatabase databaseWithPath:dbPath];
    }
    return self;
}

- (void)start
{
    NSLog(@"LocalDataManager started");
}

@end

