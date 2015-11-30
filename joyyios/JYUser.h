//
//  JYPerson.h
//  joyyios
//
//  Created by Ping Yang on 7/5/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

#import <Mantle/Mantle.h>

#import "MTLFMDBAdapter.h"

@interface JYUser : MTLModel <MTLJSONSerializing, MTLFMDBSerializing>

//+ (JYUser *)me;
//- (instancetype)initWithDictionary:(NSDictionary *)dict;
//- (void)save:(NSDictionary *)dict;

// Avatar
//@property (nonatomic) UIImage *avatarImage;
//@property (nonatomic, readonly) NSString *avatarFilename;

//@property (nonatomic) NSUInteger phoneNumber;
//@property (nonatomic) NSUInteger yearOfBirth;

// The fields only for "me"
//@property (nonatomic) NSString *cell;
//@property (nonatomic) NSString *sexCell;

@property (nonatomic) NSNumber *userId;
@property (nonatomic) NSString *username;
@property (nonatomic) NSString *avatarURL;
@property (nonatomic) NSString *sex;
@property (nonatomic) NSString *bio;
@property (nonatomic) NSString *age;
@property (nonatomic) NSUInteger yrsValue;
@property (nonatomic) UIImage *avatarImage;

@end
