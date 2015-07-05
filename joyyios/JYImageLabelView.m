//
//  JYImageLabelView.m
//  joyyios
//
//  Created by Ping Yang on 7/5/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "JYImageLabelView.h"

@interface JYImageLabelView ()
@property (nonatomic) UIImageView *imageView;
@property (nonatomic) UILabel *label;
@end

@implementation JYImageLabelView

#pragma mark - Object Lifecycle

- (id)initWithFrame:(CGRect)frame image:(UIImage *)image text:(NSString *)text
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self _createImageView:image];
        [self _createLabel:text];
    }
    return self;
}

#pragma mark - Internal Methods

- (void)_createImageView:(UIImage *)image
{
    CGFloat topPadding = 10.f;
    CGRect frame = CGRectMake(floorf((CGRectGetWidth(self.bounds) - image.size.width)/2),
                              topPadding,
                              image.size.width,
                              image.size.height);
    self.imageView = [[UIImageView alloc] initWithFrame:frame];
    self.imageView.image = image;
    [self addSubview:self.imageView];
}

- (void)_createLabel:(NSString *)text
{
    CGFloat height = 18.f;
    CGRect frame = CGRectMake(0,
                              CGRectGetMaxY(self.imageView.frame),
                              CGRectGetWidth(self.bounds),
                              height);
    self.label = [[UILabel alloc] initWithFrame:frame];
    self.label.text = text;
    self.label.textAlignment = NSTextAlignmentCenter;
    [self addSubview:self.label];
}

@end
