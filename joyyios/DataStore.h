//
//  DataStore.h
//  joyyios
//
//  Created by Ping Yang on 3/30/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "JYOrder.h"

@interface DataStore : NSObject

+ (DataStore *)sharedInstance;

@property(nonatomic) CGFloat presentedIntroductionVersion;
@property(nonatomic) JYOrder *currentOrder;
@property(nonatomic) NSDictionary *userCredential;
@property(nonatomic) NSTimeInterval tokenExpireTime;
@property(nonatomic) NSString *deviceToken;
@property(nonatomic) NSInteger badgeCount;

@end
