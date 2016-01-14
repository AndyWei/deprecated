//
//  JYManagementDataStore.m
//  joyyios
//
//  Created by Ping Yang on 3/30/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

#import <YTKKeyValueStore/YTKKeyValueStore.h>

#import "JYManagementDataStore.h"

static NSString *const kKeyShowedIntroductionVersion = @"ShowedIntroductionVersion";
static NSString *const kKeyShowedFeedsViewTipsVersion = @"ShowedFeedsViewTipsVersion";
static NSString *const kKeyShowedPeopleViewTipsVersion = @"ShowedPeopleViewTipsVersion";

static NSString *const kTableNameUser = @"user_table";

@interface JYManagementDataStore ()
@property (nonatomic) YTKKeyValueStore *store;
@end

@implementation JYManagementDataStore

+ (JYManagementDataStore *)sharedInstance
{
    static JYManagementDataStore *_sharedInstance = nil;
    static dispatch_once_t done;

    dispatch_once(&done, ^{
        _sharedInstance = [JYManagementDataStore new];
    });

    return _sharedInstance;
}

- (YTKKeyValueStore *)store
{
    if (!_store)
    {
        _store = [[YTKKeyValueStore alloc] initDBWithName:@"joyy_kv.db"];
//        [_store createTableWithName:kTableNameUser];
    }
    return _store;
}

#pragma mark - version related flags

- (BOOL)didShowIntroduction
{
    CGFloat showedVersion = [[NSUserDefaults standardUserDefaults] floatForKey:kKeyShowedIntroductionVersion];
    return (showedVersion >= kVersionIntroduction);
}

- (void)setDidShowIntroduction:(BOOL)didShowIntroduction
{
    if (didShowIntroduction)
    {
        [[NSUserDefaults standardUserDefaults] setFloat:kVersionIntroduction forKey:kKeyShowedIntroductionVersion];
    }
}

- (BOOL)didShowFeedsViewTips
{
    CGFloat showedVersion = [[NSUserDefaults standardUserDefaults] floatForKey:kKeyShowedFeedsViewTipsVersion];
    return (showedVersion >= kVersionFeedsViewTips);
}

- (void)setDidShowFeedsViewTips:(BOOL)didShowFeedsViewTips
{
    if (didShowFeedsViewTips)
    {
        [[NSUserDefaults standardUserDefaults] setFloat:kVersionFeedsViewTips forKey:kKeyShowedFeedsViewTipsVersion];
    }
}

- (BOOL)didShowPeopleViewTips
{
    CGFloat showedVersion = [[NSUserDefaults standardUserDefaults] floatForKey:kKeyShowedPeopleViewTipsVersion];
    return (showedVersion >= kVersionPeopleViewTips);
}

- (void)setDidShowPeopleViewTips:(BOOL)didShowPeopleViewTips
{
    if (didShowPeopleViewTips)
    {
        [[NSUserDefaults standardUserDefaults] setFloat:kVersionPeopleViewTips forKey:kKeyShowedPeopleViewTipsVersion];
    }
}

@end
