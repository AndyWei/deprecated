//
//  JYFilename.h
//  joyyios
//
//  Created by Ping Yang on 9/2/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

@interface JYFilename : NSObject

+ (JYFilename *)sharedInstance;

- (NSString *)URLPrefixOfRegionValue:(NSString *)regionValue;

- (NSString *)newAvatarFilename;
- (NSString *)randomFourDigits;
- (NSString *)randomFilenameWithHttpContentType:(NSString *)contentType;
- (NSString *)randomFilenameWithSuffix:(NSString *)suffix;
- (NSString *)timeInMiliSeconds;
- (NSString *)urlForAvatarWithRegion:(NSString *)region filename:(NSString *)filename;
- (NSString *)urlForPostWithRegion:(NSString *)region filename:(NSString *)filename;
- (NSString *)urlWithRegion:(NSString *)region filename:(NSString *)filename type:(NSString *)type;

@property (nonatomic) NSString *countryCode;
@property (nonatomic) NSString *avatarBucketName;
@property (nonatomic) NSString *messageBucketName;
@property (nonatomic) NSString *postBucketName;
@property (nonatomic) NSUInteger region;


@end
