//
//  JYAvatar.m
//  joyyios
//
//  Created by Ping Yang on 8/8/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

#import <CommonCrypto/CommonDigest.h>

#import "JYAvatar.h"

static NSArray *colorMap = nil;
static NSArray *symbolMap = nil;

@implementation JYAvatar

+ (JYAvatar *)avatarOfCode:(uint64_t)code
{
    uint64_t hash = [JYAvatar hashOfCode:code];
    JYAvatar *avatar = [[JYAvatar alloc] initWithHash:hash];
    return avatar;
}

+ (UIColor *)colorOfHash:(uint64_t)hash
{
    if (!colorMap)
    {
        colorMap = @[FlatBlue, FlatCoffee, FlatLime, FlatMagenta, FlatMaroon, FlatMint, FlatOrange, FlatPink];
    }

    NSUInteger index = hash % (colorMap.count);
    return colorMap[index];
}

+ (NSString *)symbolOfHash:(uint64_t)hash
{
    if (!symbolMap)
    {
        symbolMap = @[@"🐹", @"🐮", @"🐯", @"🐰", @"🐱", @"🐶", @"🐨", @"🐼", @"🐵", @"🐍",
                      @"🐸", @"🐙", @"🐌", @"🐞", @"🐘", @"🐳", @"🐋", @"🐝", @"🐠", @"🐤"];
    }

    NSAssert(colorMap && colorMap.count > 0, @"colorMap hasn't been inited");
    NSUInteger index = (hash / colorMap.count) % (symbolMap.count);
    return symbolMap[index];
}

+ (uint64_t)hashOfCode:(uint64_t)code
{
    // md5 hash
    NSString *str = [NSString stringWithFormat:@"%020tu", code];
    const char *cstr = [str UTF8String];
    unsigned char md5[CC_MD5_DIGEST_LENGTH];
    CC_MD5(cstr, (CC_LONG)strlen(cstr), md5);

    uint64_t hash = 0;
    for (NSUInteger i = 0; i < CC_MD5_DIGEST_LENGTH; ++i)
    {
        hash += md5[i];
    }

    return hash;
}

- (instancetype)initWithHash:(uint64_t)hash
{
    self = [super init];
    if (self)
    {
        _color  = [[self class] colorOfHash:hash];
        _symbol = [[self class] symbolOfHash:hash];
    }
    return self;
}

@end
