//
//  DataStore.m
//  joyyios
//
//  Created by Andy Wei on 3/30/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "DataStore.h"

@implementation DataStore

+ (DataStore *)sharedInstance
{
    static DataStore *_sharedInstance;
    static dispatch_once_t done;
    dispatch_once(&done, ^{
        _sharedInstance = [DataStore new];
    });
    return _sharedInstance;
}

- (void)saveUserCredential:(NSDictionary *)credential
{
    [[NSUserDefaults standardUserDefaults] setObject:credential forKey:kKeyUserCredential];
}

- (NSDictionary *)loadUserCredential
{
    NSDictionary *credential = nil;
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kKeyUserCredential])
    {
        credential = [[NSUserDefaults standardUserDefaults] objectForKey:kKeyUserCredential];
    }
    return credential;
}

@end
