//
//  JYDataStore.m
//  joyyios
//
//  Created by Ping Yang on 3/30/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

#import "JYDataStore.h"

NSString *const kKeyBadgeCount = @"BadgeCount";
NSString *const kKeyDeviceToken = @"DeviceToken";
NSString *const kKeyPresentedIntroductionVersion = @"PresentedIntroductionVersion";

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
        [_store createTableWithName:kTableNamePerson];
    }
    return _store;
}

- (void)getPersonWithIdString:(NSString *)idString
                      success:(void (^)(JYPerson *person))success
                      failure:(void (^)(NSError *error))failure
{
    // input check
    if (!idString || [idString unsignedIntegerValue] == 0)
    {
        NSError *error = [NSError errorWithDomain:@"JYDataStore" code:0 userInfo:nil];
        return failure(error);
    }

    // local lookup
    NSDictionary *personDict = [self.store getObjectById:idString fromTable:kTableNamePerson];
    if (personDict)
    {
        JYPerson *person = [[JYPerson alloc] initWithDictionary:personDict];
        return success(person);
    }

    // fetch from server
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager managerWithToken];
    NSString *url = [NSString apiURLWithPath:@"person"];
    NSDictionary *parameters =  @{ @"id": @[idString] };

    __weak typeof(self) weakSelf = self;
    [manager GET:url
      parameters:parameters
         success:^(AFHTTPRequestOperation *operation, id responseObject) {
             NSLog(@"Success: JYDataStore fetch person responseObject: %@", responseObject);

             NSDictionary *dict = [responseObject firstObject];
             if (dict)
             {
                 [weakSelf.store putObject:dict withId:idString intoTable:kTableNamePerson];
                 JYPerson *person = [[JYPerson alloc] initWithDictionary:dict];
                 return success(person);
             }
             else
             {
                 NSError *error = [NSError errorWithDomain:@"JYDataStore" code:1 userInfo:nil];
                 return failure(error);
             }
         }
         failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             NSLog(@"Failure: JYDataStore fetch person error: %@", error);
             return failure(error);
         }
     ];
}

// DeviceToken
- (void)setDeviceToken:(NSString *)token
{
    [[NSUserDefaults standardUserDefaults] setObject:token forKey:kKeyDeviceToken];
}

- (NSString *)deviceToken
{
    return [[NSUserDefaults standardUserDefaults] stringForKey:kKeyDeviceToken];
}

// BadgeCount
- (void)setBadgeCount:(NSInteger)count
{
    [[NSUserDefaults standardUserDefaults] setInteger:count forKey:kKeyBadgeCount];
}

- (NSInteger)badgeCount
{
    return[[NSUserDefaults standardUserDefaults] integerForKey:kKeyBadgeCount];
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

@end
