//
//  JYPerson.h
//  joyyios
//
//  Created by Ping Yang on 7/5/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

@interface JYPerson : NSObject

+ (JYPerson *)me;
- (instancetype)initWithDictionary:(NSDictionary *)dict;
- (void)save:(NSDictionary *)dict;

// Identities
@property (nonatomic) NSUInteger personId;
@property (nonatomic) NSString *username;
@property (nonatomic, readonly) NSString *idString;

// Avatar
@property (nonatomic) UIImage *avatarImage;
@property (nonatomic, readonly) NSString *avatarFilename;
@property (nonatomic, readonly) NSString *avatarURL;

// Profile
@property (nonatomic) NSString *sex;
@property (nonatomic) NSString *sexualOrientation;
@property (nonatomic) NSString *bio;
@property (nonatomic) NSUInteger yearOfBirth;
@property (nonatomic) NSUInteger friendCount;
@property (nonatomic) NSUInteger winkCount;
@property (nonatomic) NSUInteger score;
@property (nonatomic, readonly) NSString *ageString;


// The fields only for "me"
@property (nonatomic) NSString *cell;
@property (nonatomic) NSString *sexCell;

@end
