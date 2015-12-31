//
//  JYUser.h
//  joyyios
//
//  Created by Ping Yang on 7/5/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

#import <Mantle/Mantle.h>

#import "MTLFMDBAdapter.h"

@interface JYUser : MTLModel <MTLJSONSerializing, MTLFMDBSerializing>

- (NSString *)reversedIdString;
- (NSString *)nextS3Filename;

@property (nonatomic) NSNumber *userId;
@property (nonatomic) NSString *username;
@property (nonatomic) NSString *avatarURL;
@property (nonatomic) NSString *sex;
@property (nonatomic) NSString *bio;
@property (nonatomic) NSString *age;
@property (nonatomic) uint64_t yrsValue;
@property (nonatomic) UIImage *avatarImage;

@end
