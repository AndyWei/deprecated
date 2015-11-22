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

- (void)getUserWithIdString:(NSString *)idString
                      success:(void (^)(JYUser *user))success
                      failure:(void (^)(NSError *error))failure
{
    // input check
    if (!idString || [idString uint64Value] == 0)
    {
        NSError *error = [NSError errorWithDomain:@"JYDataStore" code:0 userInfo:nil];
        return failure(error);
    }

    // local lookup
    NSDictionary *userDict = [self.store getObjectById:idString fromTable:kTableNameUser];
    if (userDict)
    {
        JYUser *user = [[JYUser alloc] initWithDictionary:userDict];
        return success(user);
    }

    // fetch from server
    AFHTTPSessionManager *manager = [AFHTTPSessionManager managerWithToken];
    NSString *url = [NSString apiURLWithPath:@"user"];
    NSDictionary *parameters =  @{ @"id": @[idString] };

    __weak typeof(self) weakSelf = self;
    [manager GET:url
      parameters:parameters
         success:^(NSURLSessionTask *operation, id responseObject) {
             NSLog(@"Success: JYDataStore fetch user responseObject: %@", responseObject);

             NSDictionary *dict = [responseObject firstObject];
             if (dict)
             {
                 [weakSelf.store putObject:dict withId:idString intoTable:kTableNameUser];
                 JYUser *user = [[JYUser alloc] initWithDictionary:dict];
                 return success(user);
             }
             else
             {
                 NSError *error = [NSError errorWithDomain:@"JYDataStore" code:1 userInfo:nil];
                 return failure(error);
             }
         }
         failure:^(NSURLSessionTask *operation, NSError *error) {
             NSLog(@"Failure: JYDataStore fetch user error: %@", error);
             return failure(error);
         }
     ];
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
