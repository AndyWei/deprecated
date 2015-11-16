//
//  JYPost.m
//  joyyios
//
//  Created by Ping Yang on 7/12/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

#import "JYFilename.h"
#import "JYPost.h"

@interface JYPost ()
@end

@implementation JYPost

#pragma mark - MTLJSONSerializing methods

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
             @"postId": @"postid",
             @"ownerId": @"ownerid",
             @"shortURL": @"url",
             @"caption": @"caption",
             };
}

#pragma mark - MTLFMDBSerializing methods

+ (NSDictionary *)FMDBColumnsByPropertyKey
{
    return @{
             @"postId": @"id",
             @"ownerId": @"ownerid",
             @"shortURL": @"url",
             @"caption": @"caption",
             @"idString": [NSNull null],
             @"URL": [NSNull null],
             @"timestamp": [NSNull null],
             @"commentList": [NSNull null],
             @"isLiked": [NSNull null]
             };
}

+ (NSArray *)FMDBPrimaryKeys
{
    return @[@"id"];
}

+ (NSString *)FMDBTableName
{
    return @"post";
}

#pragma mark - Life Cycle

+ (instancetype)postWithDictionary:(NSDictionary *)dict
{
    NSError *error;
    return [[JYPost alloc] initWithDictionary:dict error:&error];
}

- (instancetype)initWithDictionary:(NSDictionary *)dict error:(NSError **)error
{
    self = [super initWithDictionary:dict error:error];
    if (self == nil || dict == nil)
    {
        return self;
    }

    _idString = [NSString stringWithFormat:@"%tu", _postId];

    _isLiked = [self _isInLikedStore];

    if ([kDummyCaptionText isEqualToString:_caption])
    {
        _caption = @"";
    }

    NSArray *array = [_shortURL componentsSeparatedByString:@":"];

    if ([array count] != 2)
    {
        return nil;
    }

    NSString *regionValue = array[0];
    NSString *prefix = [[JYFilename sharedInstance] URLPrefixOfRegionValue:regionValue];
    NSString *filename = array[1];
    _URL = [prefix stringByAppendingString:filename];

    return self;
}

- (void)setIsLiked:(BOOL)isLiked
{
    if (isLiked)
    {
        NSDictionary *value = @{ @"userid": [JYCredential current].idString };
        [[JYDataStore sharedInstance].store putObject:value withId:self.idString intoTable:kTableNameLikedPost];
    }

    _isLiked = isLiked;
}

- (BOOL)_isInLikedStore
{
    NSDictionary *liked = [[JYDataStore sharedInstance].store getObjectById:self.idString fromTable:kTableNameLikedPost];
    if (!liked)
    {
        return NO;
    }

    NSUInteger likedByPerson = [[liked objectForKey:@"userid"] unsignedIntegerValue];
    return (likedByPerson == [JYCredential current].userId);
}

- (uint64_t)timestamp
{
    uint64_t postid = self.postId;
    return (postid >> 32);
}

@end
