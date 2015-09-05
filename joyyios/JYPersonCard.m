//
//  JYPersonCard.m
//  joyyios
//
//  Created by Ping Yang on 7/5/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

#import <AFNetworking/UIImageView+AFNetworking.h>
#import <TTTAttributedLabel/TTTAttributedLabel.h>

#import "JYButton.h"
#import "JYPersonCard.h"

static const CGFloat kLabelHeight = 40.f;
static const CGFloat kInfoLabelWidth = 280.f;

@interface JYPersonCard ()
@property(nonatomic) JYButton *heartCountView;
@property(nonatomic) TTTAttributedLabel *infoLabel;
@end

@implementation JYPersonCard

- (instancetype)initWithFrame:(CGRect)frame options:(MDCSwipeToChooseViewOptions *)options
{
    self = [super initWithFrame:frame options:options];
    if (self)
    {
        self.autoresizingMask = UIViewAutoresizingFlexibleHeight |
                                UIViewAutoresizingFlexibleWidth |
                                UIViewAutoresizingFlexibleBottomMargin;
        self.imageView.autoresizingMask = self.autoresizingMask;
    }
    return self;
}

- (TTTAttributedLabel *)infoLabel
{
    if (!_infoLabel)
    {
        CGFloat y = CGRectGetHeight(self.bounds) - kLabelHeight;
        CGRect frame = CGRectMake(0, y, kInfoLabelWidth, kLabelHeight);
        _infoLabel = [self _labelWithFrame:frame];

        [self addSubview:_infoLabel];
    }

    return _infoLabel;
}

- (JYButton *)heartCountView
{
    if (!_heartCountView)
    {
        CGFloat x = CGRectGetMaxX(self.infoLabel.bounds);
        CGFloat y = CGRectGetHeight(self.bounds) - kLabelHeight;
        CGFloat width = CGRectGetWidth(self.bounds) - kInfoLabelWidth;
        CGRect frame = CGRectMake(x, y, width, kLabelHeight);
        _heartCountView = [JYButton buttonWithFrame:frame buttonStyle:JYButtonStyleImageWithTitle shouldMaskImage:YES];
        _heartCountView.imageView.image = [UIImage imageNamed:@"like"];
        _heartCountView.contentColor = JoyyBlue;
        _heartCountView.foregroundColor = JoyyBlack50;

        [self addSubview:_heartCountView];
    }

    return _heartCountView;
}

- (TTTAttributedLabel *)_labelWithFrame:(CGRect)frame
{
    TTTAttributedLabel *label = [[TTTAttributedLabel alloc] initWithFrame:frame];
    label.backgroundColor = JoyyBlack50;
    label.textColor = JoyyWhite;
    label.textInsets = UIEdgeInsetsMake(0, 10, 0, 0);

    return label;
}

- (void)setPerson:(JYPerson *)person
{
    if (!person)
    {
        return;
    }

    _person = person;

    [self _updateImage];
    [self _updateInfoLabel];
    [self _updateHeartCount];
}

- (void)_updateImage
{
    // Fetch network image
    NSURL *avatarURL = [NSURL URLWithString:self.person.avatarURL];
    NSURLRequest *request = [NSURLRequest requestWithURL:avatarURL];

    __weak typeof(self) weakSelf = self;
    [self.imageView setImageWithURLRequest:request
                          placeholderImage:nil
                                   success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image)
     {
         weakSelf.imageView.image = image;
         [weakSelf setNeedsLayout];
     } failure:nil];
}

- (void)_updateInfoLabel
{
    if (self.person.ageString)
    {
        self.infoLabel.text = [NSString stringWithFormat:@"%@, %@, %@", self.person.name, self.person.org, self.person.ageString];
    }
    else
    {
        self.infoLabel.text = [NSString stringWithFormat:@"%@, %@", self.person.name, self.person.org];
    }
}

- (void)_updateHeartCount
{
    self.heartCountView.textLabel.text = [NSString stringWithFormat:@"%tu", self.person.heartCount];
}

@end
