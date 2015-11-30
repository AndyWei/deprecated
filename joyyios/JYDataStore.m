//
//  JYDataStore.m
//  joyyios
//
//  Created by Ping Yang on 3/30/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

#import "JYDataStore.h"

NSString *const kKeyPresentedIntroductionVersion = @"PresentedIntroductionVersion";
NSString *const kTableNameLikedPost = @"liked_post";
NSString *const kTableNameUser = @"user_table";

@interface JYDataStore ()
@end

@implementation JYDataStore

+ (JYDataStore *)sharedInstance
{
    static JYDataStore *_sharedInstance = nil;
    static dispatch_once_t done;

    dispatch_once(&done, ^{
        _sharedInstance = [JYDataStore new];
    });

    return _sharedInstance;
}

- (YTKKeyValueStore *)store
{
    if (!_store)
    {
        _store = [[YTKKeyValueStore alloc] initDBWithName:@"joyy_kv.db"];
        [_store createTableWithName:kTableNameLikedPost];
        [_store createTableWithName:kTableNameUser];
    }
    return _store;
}

// IntroductionVersion
- (void)setPresentedIntroductionVersion:(CGFloat)version
{
    [[NSUserDefaults standardUserDefaults] setFloat:version forKey:kKeyPresentedIntroductionVersion];
}

- (CGFloat)presentedIntroductionVersion
{
    return[[NSUserDefaults standardUserDefaults] floatForKey:kKeyPresentedIntroductionVersion];
}

- (NSString *)usernameOfId:(NSNumber *)userid
{
    NSString *userIdStr = [NSString stringWithFormat:@"%llu", [userid unsignedLongLongValue]];
    NSDictionary *userDict = [self.store getObjectById:userIdStr fromTable:kTableNameUser];
    return [userDict objectForKey:@"username"];
}

@end
