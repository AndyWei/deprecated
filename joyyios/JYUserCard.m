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
#import "JYUserCard.h"

static const CGFloat kLabelHeight = 40.f;
static const CGFloat kInfoLabelWidth = 280.f;

@interface JYUserCard ()
@property(nonatomic) JYButton *winkCountView;
@property(nonatomic) TTTAttributedLabel *infoLabel;
@end

@implementation JYUserCard

+ (UIImage *)winkImage
{
    static UIImage *_sharedWinkImage = nil;

    if (!_sharedWinkImage)
    {
        _sharedWinkImage = [UIImage imageNamed:@"wink"];
    }

    return _sharedWinkImage;
}

- (instancetype)initWithFrame:(CGRect)frame options:(MDCSwipeToChooseViewOptions *)options
{
    self = [super initWithFrame:frame options:options];
    if (self)
    {
        self.autoresizingMask = UIViewAutoresizingFlexibleHeight |
                                UIViewAutoresizingFlexibleWidth |
                                UIViewAutoresizingFlexibleBottomMargin;
        self.imageView.autoresizingMask = self.autoresizingMask;
        self.backgroundColor = JoyyWhitePure;

        [self addSubview:self.infoLabel];
    }
    return self;
}

- (TTTAttributedLabel *)infoLabel
{
    if (!_infoLabel)
    {
        _infoLabel = [self _labelWithFrame:CGRectZero];
    }

    return _infoLabel;
}

- (JYButton *)winkCountView
{
    if (!_winkCountView)
    {
        CGFloat x = CGRectGetMaxX(self.infoLabel.bounds);
        CGFloat y = CGRectGetHeight(self.bounds) - kLabelHeight;
        CGFloat width = CGRectGetWidth(self.bounds) - kInfoLabelWidth;
        CGRect frame = CGRectMake(x, y, width, kLabelHeight);
        _winkCountView = [JYButton buttonWithFrame:frame buttonStyle:JYButtonStyleImageWithTitle shouldMaskImage:YES];
        _winkCountView.imageView.image = [[self class] winkImage];
        _winkCountView.contentColor = JoyyBlue;
        _winkCountView.foregroundColor = JoyyBlack50;

        [self addSubview:_winkCountView];
    }

    return _winkCountView;
}

- (TTTAttributedLabel *)_labelWithFrame:(CGRect)frame
{
    TTTAttributedLabel *label = [[TTTAttributedLabel alloc] initWithFrame:frame];
    label.backgroundColor = JoyyBlack80;
    label.font = [UIFont systemFontOfSize:kFontSizeCaption];
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = JoyyWhite;
    label.textInsets = UIEdgeInsetsMake(0, kMarginLeft, 0, kMarginRight);

    label.lineBreakMode = NSLineBreakByWordWrapping;
    label.numberOfLines = 0;

    label.layer.cornerRadius = 4;
    label.clipsToBounds = YES;

    return label;
}

- (void)setUser:(JYUser *)user
{
    if (!user)
    {
        return;
    }

    _user = user;
    [self _updateImage];
    [self _updateInfoLabel];
}

- (void)_updateImage
{
    // Get network image
    NSURLRequest *request = [NSURLRequest requestWithURL:self.user.avatarURL cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:5];

    __weak typeof(self) weakSelf = self;
    [self.imageView setImageWithURLRequest:request
                          placeholderImage:nil
                                   success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image)
     {
         NSLog(@"Success: get person full avatar");
         [weakSelf _didLoadImage:image];
     }
     failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error)
     {
         NSLog(@"Error: get person full avatar error: %@", error);
     }];
}

- (void)_didLoadImage:(UIImage *)image
{
    self.imageView.image = image;
    [self setNeedsLayout];
}

- (void)_updateInfoLabel
{
    self.infoLabel.text = [NSString stringWithFormat:@"%@", self.user.username];

    CGFloat cardWidth = CGRectGetWidth(self.bounds);
    CGFloat cardHeight = CGRectGetHeight(self.bounds);
    self.infoLabel.width = cardWidth - 30;

    [self.infoLabel sizeToFit];
    self.infoLabel.centerX = cardWidth/2;
    self.infoLabel.y = cardHeight - self.infoLabel.height - 10;
}

@end
