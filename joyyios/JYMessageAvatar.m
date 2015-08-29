//
//  JYMessageAvatar.m
//  joyyios
//
//  Created by Ping Yang on 8/24/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

#import "JYMessageAvatar.h"

@implementation JYMessageAvatar

+ (instancetype)avatarWithImage:(UIImage *)image
{
    NSParameterAssert(image != nil);

    return [[JYMessageAvatar alloc] initWithAvatarImage:image
                                              highlightedImage:image
                                              placeholderImage:image];
}

+ (instancetype)avatarImageWithPlaceholder:(UIImage *)placeholderImage
{
    return [[JYMessageAvatar alloc] initWithAvatarImage:nil
                                              highlightedImage:nil
                                              placeholderImage:placeholderImage];
}

- (instancetype)initWithAvatarImage:(UIImage *)avatarImage
                   highlightedImage:(UIImage *)highlightedImage
                   placeholderImage:(UIImage *)placeholderImage
{
    NSParameterAssert(placeholderImage != nil);

    self = [super init];
    if (self) {
        _avatarImage = avatarImage;
        _avatarHighlightedImage = highlightedImage;
        _avatarPlaceholderImage = placeholderImage;
    }
    return self;
}

- (id)init
{
    NSAssert(NO, @"%s is not a valid initializer for %@. Use %@ instead.",
             __PRETTY_FUNCTION__, [self class], NSStringFromSelector(@selector(initWithAvatarImage:highlightedImage:placeholderImage:)));
    return nil;
}

#pragma mark - NSObject

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: avatarImage=%@, avatarHighlightedImage=%@, avatarPlaceholderImage=%@>",
            [self class], self.avatarImage, self.avatarHighlightedImage, self.avatarPlaceholderImage];
}

@end
