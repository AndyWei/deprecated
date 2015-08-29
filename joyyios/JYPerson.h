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

@property(nonatomic) BOOL isVerified;
@property(nonatomic) JYGender gender;
@property(nonatomic) JYOrgType orgType;

@property(nonatomic) NSString *age;
@property(nonatomic) NSString *avatarUrl;
@property(nonatomic) NSString *bio;
@property(nonatomic) NSString *idString;
@property(nonatomic) NSString *messageAvatarUrl;
@property(nonatomic) NSString *name;
@property(nonatomic) NSString *org;

@property(nonatomic) NSUInteger friendCount;
@property(nonatomic) NSUInteger heartCount;
@property(nonatomic) NSUInteger personId;
@property(nonatomic) NSUInteger score;


+ (JYPerson *)me;
- (instancetype)initWithDictionary:(NSDictionary *)dict;

@end
