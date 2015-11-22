//
//  JYPerson.h
//  joyyios
//
//  Created by Ping Yang on 7/5/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

@interface JYUser : NSObject

//+ (JYUser *)me;
- (instancetype)initWithDictionary:(NSDictionary *)dict;
- (void)save:(NSDictionary *)dict;

// Identities
@property (nonatomic) NSNumber *userId;
@property (nonatomic) NSString *username;

// Avatar
@property (nonatomic) UIImage *avatarImage;
@property (nonatomic, readonly) NSString *avatarFilename;
@property (nonatomic, readonly) NSString *avatarURL;

// Profile
@property (nonatomic) NSString *sex;
@property (nonatomic) NSString *sexualOrientation;
@property (nonatomic) NSString *bio;
@property (nonatomic) NSUInteger phoneNumber;
@property (nonatomic) NSUInteger yearOfBirth;
@property (nonatomic) uint64_t yrs;
@property (nonatomic, readonly) NSString *ageString;


// The fields only for "me"
@property (nonatomic) NSString *cell;
@property (nonatomic) NSString *sexCell;

@end
