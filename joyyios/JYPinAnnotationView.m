//
//  JYPinAnnotationView.m
//  joyyios
//
//  Created by Ping Yang on 4/2/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "JYPinAnnotationView.h"

@interface JYPinAnnotationView ()
{
    UIImageView *_annotationImageView;
}
@end

@implementation JYPinAnnotationView

- (id)initWithAnnotation:(id<MKAnnotation>)annotation reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier];

    if (self != nil)
    {
        [self _commonInit];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];

    if (self != nil)
    {
        [self _commonInit];
    }
    return self;
}

- (void)_commonInit
{
    _pinColor = JYPinAnnotationColorNone;
    self.frame = CGRectMake(0.0f, 0.0f, self.annotationImage.size.width, self.annotationImage.size.height * 2);
    self.backgroundColor = [UIColor clearColor];
}

#pragma mark - Setters
- (void)setPinColor:(JYPinAnnotationColor)pinColor
{
    if (_pinColor == pinColor)
    {
        return;
    }

    _pinColor = pinColor;

    if (_annotationImageView == nil)
    {
        _annotationImageView = [[UIImageView alloc] initWithImage:[self annotationImage]];

//        // Adjust the image view upper to make sure the pin point is at the center of bounds
//        CGFloat yOffset = self.frame.size.height / 2 + 7;
//        _annotationImageView.frame = CGRectMake(0, -yOffset, self.frame.size.width, self.frame.size.height);
        _annotationImageView.frame = CGRectMake(0, 0, self.annotationImage.size.width,self.annotationImage.size.height);

        [self addSubview:_annotationImageView];
    }

    _annotationImageView.image = [self annotationImage];
}

- (UIImage *)annotationImage
{
    UIImage *image = nil;

    switch (_pinColor)
    {
        case JYPinAnnotationColorBlue:
            image = [UIImage imageNamed:@"pinBlue"];
            break;
        case JYPinAnnotationColorGreen:
            image = [UIImage imageNamed:@"pinGreen"];
            break;
        case JYPinAnnotationColorPink:
            image = [UIImage imageNamed:@"pinPink"];
            break;
        default:
            image = [UIImage imageNamed:@"pinBlue"];
            break;
    }

    return image;
}

@end
