//
//  JYCardView.m
//  joyyios
//
//  Created by Ping Yang on 12/9/15.
//  Copyright © 2015 Joyy Inc. All rights reserved.
//

#import "JYCardView.h"

@interface JYCardView ()
@property (nonatomic) UIVisualEffectView *blurView;
@end

@implementation JYCardView

- (id)init
{
    self = [super init];
    if (self)
    {
        self.translatesAutoresizingMaskIntoConstraints = NO;
        self.backgroundColor = JoyyWhitePure;
        self.layer.cornerRadius = 5;
        self.layer.shadowRadius = 3;
        self.layer.shadowOpacity = 0;
        self.layer.shadowOffset = CGSizeMake(1, 1);

        [self addSubview:self.coverView];
        [self addSubview:self.avatarButton];
        [self addSubview:self.titleLabel];

        NSDictionary *views = @{
                                @"avatarButton": self.avatarButton,
                                @"coverView": self.coverView,
                                @"titleLabel": self.titleLabel,
                                @"blurView": self.blurView
                              };

        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[coverView]-0-|" options:0 metrics:nil views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-20-[avatarButton(120)][titleLabel]-10-|" options:0 metrics:nil views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[coverView][titleLabel(20)]-20-|" options:0 metrics:nil views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(>=30@500)-[avatarButton(120)]|" options:0 metrics:nil views:views]];

        [self.coverView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[blurView]|" options:0 metrics:nil views:views]];
        [self.coverView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[blurView]|" options:0 metrics:nil views:views]];
    }
    return self;
}

- (UIButton *)avatarButton
{
    if (!_avatarButton)
    {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.translatesAutoresizingMaskIntoConstraints = NO;
        [button addTarget:self action:@selector(_didTapAvatarButton) forControlEvents:UIControlEventTouchUpInside];
        button.clipsToBounds = YES;
        button.layer.cornerRadius = 60;

        _avatarButton = button;
    }
    return _avatarButton;
}

- (UIImageView *)coverView
{
    if (!_coverView)
    {
        _coverView = [[UIImageView alloc] init];
        _coverView.translatesAutoresizingMaskIntoConstraints = NO;
        _coverView.backgroundColor = JoyyWhitePure;
        _coverView.contentMode = UIViewContentModeScaleToFill;
        [_coverView addSubview:self.blurView];
    }
    return _coverView;
}

- (UIVisualEffectView *)blurView
{
    if (!_blurView)
    {
        UIBlurEffect* blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
        _blurView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
        _blurView.translatesAutoresizingMaskIntoConstraints = NO;
        _blurView.hidden = YES;
    }
    return _blurView;
}

- (UILabel *)titleLabel
{
    if (!_titleLabel)
    {
        UILabel *label = [[UILabel alloc] init];
        label.translatesAutoresizingMaskIntoConstraints = NO;
        label.font = [UIFont systemFontOfSize:18];
        label.textColor = JoyyGray;
        label.backgroundColor = JoyyWhitePure;
        label.textAlignment = NSTextAlignmentLeft;
        label.numberOfLines = 0;
        label.lineBreakMode = NSLineBreakByWordWrapping;

        _titleLabel = label;
    }
    return _titleLabel;
}

- (void)_didTapAvatarButton
{
    if (self.delegate)
    {
        [self.delegate didTapAvatarOnView:self];
    }
}

- (void)addShadow
{
    self.layer.shadowOpacity = 0.15;
}

- (void)removeShadow
{
    self.layer.shadowOpacity = 0;
}

-(void)addBlur
{
    self.blurView.hidden = NO;
}

-(void)removeBlur
{
    self.blurView.hidden = YES;
}

@end
