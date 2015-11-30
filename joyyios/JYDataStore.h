//
//  JYDataStore.h
//  joyyios
//
//  Created by Ping Yang on 3/30/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

#import <YTKKeyValueStore/YTKKeyValueStore.h>
#import "JYUser.h"

@import CoreLocation;

@interface JYDataStore : NSObject

+ (JYDataStore *)sharedInstance;

- (NSString *)usernameOfId:(NSNumber *)userid;

@property (nonatomic) YTKKeyValueStore *store;
@property (nonatomic) CGFloat presentedIntroductionVersion;


@end
