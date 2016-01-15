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

- (NSString *)sexLongString;
- (NSString *)nextAvatarFilename;
- (NSString *)nextAvatarThumbnailFilename;
- (NSString *)reversedIdString;

@property (nonatomic) NSNumber *isHit;
@property (nonatomic) NSNumber *isInvited;
@property (nonatomic) NSNumber *phoneNumber;
@property (nonatomic) NSNumber *userId;
@property (nonatomic) NSNumber *yrsNumber;
@property (nonatomic) NSString *username;
@property (nonatomic) NSString *sex;
@property (nonatomic) NSString *bio;
@property (nonatomic) NSString *age;
@property (nonatomic) NSURL *avatarURL;
@property (nonatomic) NSURL *avatarThumbnailURL;
@property (nonatomic) UIImage *avatarImage;

@end
