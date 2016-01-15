//
//  JYManagementDataStore.m
//  joyyios
//
//  Created by Ping Yang on 3/30/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

#import <YTKKeyValueStore/YTKKeyValueStore.h>

#import "JYManagementDataStore.h"

static CGFloat const kIntroductionVersion = 1.0;
static CGFloat const kFeedsViewTipsVersion = 1.0;
static CGFloat const kPeopleViewTipsVersion = 1.0;

static NSString *const kLastContactsQueryDateKey = @"LastContactsQueryDate";
static NSString *const kShowedIntroductionVersionKey = @"ShowedIntroductionVersion";
static NSString *const kShowedFeedsViewTipsVersionKey = @"ShowedFeedsViewTipsVersion";
static NSString *const kShowedPeopleViewTipsVersionKey = @"ShowedPeopleViewTipsVersion";

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
    CGFloat showedVersion = [[NSUserDefaults standardUserDefaults] floatForKey:kShowedIntroductionVersionKey];
    return (showedVersion >= kIntroductionVersion);
}

- (void)setDidShowIntroduction:(BOOL)didShowIntroduction
{
    if (didShowIntroduction)
    {
        [[NSUserDefaults standardUserDefaults] setFloat:kIntroductionVersion forKey:kShowedIntroductionVersionKey];
    }
}

- (BOOL)didShowFeedsViewTips
{
    CGFloat showedVersion = [[NSUserDefaults standardUserDefaults] floatForKey:kShowedFeedsViewTipsVersionKey];
    return (showedVersion >= kFeedsViewTipsVersion);
}

- (void)setDidShowFeedsViewTips:(BOOL)didShowFeedsViewTips
{
    if (didShowFeedsViewTips)
    {
        [[NSUserDefaults standardUserDefaults] setFloat:kFeedsViewTipsVersion forKey:kShowedFeedsViewTipsVersionKey];
    }
}

- (BOOL)didShowPeopleViewTips
{
    CGFloat showedVersion = [[NSUserDefaults standardUserDefaults] floatForKey:kShowedPeopleViewTipsVersionKey];
    return (showedVersion >= kPeopleViewTipsVersion);
}

- (void)setDidShowPeopleViewTips:(BOOL)didShowPeopleViewTips
{
    if (didShowPeopleViewTips)
    {
        [[NSUserDefaults standardUserDefaults] setFloat:kPeopleViewTipsVersion forKey:kShowedPeopleViewTipsVersionKey];
    }
}

- (BOOL)needQueryContacts
{
    NSDate *lastQueryDate = (NSDate *)[[NSUserDefaults standardUserDefaults] objectForKey:kLastContactsQueryDateKey];
    if (!lastQueryDate)
    {
        return YES;
    }

    NSTimeInterval passedSecs = -[lastQueryDate timeIntervalSinceNow];
    return (passedSecs > kSecondsOfDay);
}

- (void)setNeedQueryContacts:(BOOL)needQueryContacts
{
    if (needQueryContacts)
    {
        [[NSUserDefaults standardUserDefaults] setObject:[NSDate dateWithTimeIntervalSince1970:0] forKey:kLastContactsQueryDateKey];
    }
    else
    {
        [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:kLastContactsQueryDateKey];
    }
}

@end
