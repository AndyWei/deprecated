//
//  JYPerson.h
//  joyyios
//
//  Created by Ping Yang on 7/5/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

typedef NS_ENUM(NSUInteger, JYGender)
{
    JYGenderUnknown = 0,
    JYGenderMale    = 1,
    JYGenderFemale  = 2,
    JYGenderOther   = 3
};

typedef NS_ENUM(NSUInteger, JYOrgType)
{
    JYOrgTypeUnknown = 0,
    JYOrgTypeCom     = 1,
    JYOrgTypeEdu     = 2,
    JYOrgTypeOrg     = 3,
    JYOrgTypeGov     = 4,
    JYOrgTypeOther   = 100
};

@interface JYPerson : NSObject

+ (JYPerson *)me;
- (instancetype)initWithDictionary:(NSDictionary *)dict;

// Identities
@property(nonatomic, readonly) NSString *idString;
@property(nonatomic) NSUInteger personId;
@property(nonatomic) NSString *name;

// Avatar
@property(nonatomic) UIImage *avatarImage;
@property(nonatomic, readonly) NSString *avatarURL;
@property(nonatomic, readonly) NSString *fullAvatarURL;

// Profile
@property(nonatomic) BOOL isVerified;
@property(nonatomic) JYGender gender;
@property(nonatomic) JYOrgType orgType;
@property(nonatomic) NSString *bio;
@property(nonatomic) NSString *org;
@property(nonatomic) NSUInteger yearOfBirth;
@property(nonatomic) NSUInteger friendCount;
@property(nonatomic) NSUInteger heartCount;
@property(nonatomic) NSUInteger score;
@property(nonatomic, readonly) NSString *ageString;




@end
