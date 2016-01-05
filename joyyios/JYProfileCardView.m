//
//  JYProfileCardView.m
//  joyyios
//
//  Created by Ping Yang on 12/23/15.
//  Copyright © 2015 Joyy Inc. All rights reserved.
//

#import <AFNetworking/UIButton+AFNetworking.h>
#import <TTTAttributedLabel/TTTAttributedLabel.h>

#import "JYButton.h"
#import "JYProfileCardView.h"

@interface JYProfileCardView () <TTTAttributedLabelDelegate>
@property (nonatomic) JYButton *sexButton;
@property (nonatomic) TTTAttributedLabel *usernameLabel;
@property (nonatomic) TTTAttributedLabel *friendCountLabel;
@property (nonatomic) TTTAttributedLabel *friendsLabel;
@property (nonatomic) TTTAttributedLabel *contactCountLabel;
@property (nonatomic) TTTAttributedLabel *contactsLabel;
@property (nonatomic) TTTAttributedLabel *winkCountLabel;
@property (nonatomic) TTTAttributedLabel *winksLabel;
@end

static NSString *kFriendURL = @"action://_didTapFriendLabel";
static NSString *kContactURL = @"action://_didTapContactLabel";
static NSString *kWinkURL = @"action://_didTapWinkLabel";

@implementation JYProfileCardView

- (id)init
{
    self = [super init];
    if (self)
    {
        self.translatesAutoresizingMaskIntoConstraints = NO;
        self.backgroundColor = JoyyWhitePure;

        [self addSubview:self.avatarButton];
        [self addSubview:self.usernameLabel];
        [self addSubview:self.friendCountLabel];
        [self addSubview:self.friendsLabel];
        [self addSubview:self.contactCountLabel];
        [self addSubview:self.contactsLabel];
        [self addSubview:self.winkCountLabel];
        [self addSubview:self.winksLabel];
        [self addSubview:self.sexButton];

        self.friendCount = self.contactCount = self.winkCount = 0;

        NSDictionary *views = @{
                                @"avatarButton": self.avatarButton,
                                @"usernameLabel": self.usernameLabel,
                                @"friendCountLabel": self.friendCountLabel,
                                @"friendsLabel": self.friendsLabel,
                                @"contactCountLabel": self.contactCountLabel,
                                @"contactsLabel": self.contactsLabel,
                                @"winkCountLabel": self.winkCountLabel,
                                @"winksLabel": self.winksLabel,
                                @"sexButton": self.sexButton
                                };

        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-10-[avatarButton(80)]-20-[friendCountLabel(60)]-10-[contactCountLabel(60)]-10-[winkCountLabel(60)]-(>=0@500)-|" options:0 metrics:nil views:views]];

        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-10-[avatarButton(80)]-20-[friendsLabel(60)]-10-[contactsLabel(60)]-10-[winksLabel(60)]-(>=0@500)-|" options:0 metrics:nil views:views]];

        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-10-[sexButton(20)]-10-[usernameLabel(300)]-(>=10@500)-|" options:0 metrics:nil views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-10-[avatarButton(80)]-10-[sexButton(20)]-10-|" options:0 metrics:nil views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-10-[avatarButton(80)]-10-[usernameLabel]-10-|" options:0 metrics:nil views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-10-[friendCountLabel][friendsLabel]-(>=0@500)-|" options:0 metrics:nil views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-10-[contactCountLabel][contactsLabel]-(>=0@500)-|" options:0 metrics:nil views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-10-[winkCountLabel][winksLabel]-(>=10@500)-|" options:0 metrics:nil views:views]];

        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-10-[avatarButton(80)]-(>=0@500)-|" options:0 metrics:nil views:views]];
    }
    return self;
}

- (void)setUser:(JYUser *)user
{
    if (_user == user || !user)
    {
        return;
    }

    _user = user;

    [self.avatarButton setImageForState:UIControlStateNormal withURL:user.avatarURL];

    self.usernameLabel.text = user.username;

    if ([user.sex isEqualToString:@"F"])
    {
        self.sexButton.imageView.image = [UIImage imageNamed:@"girl"];
        self.sexButton.contentColor = JoyyPink;
    }
    else
    {
        self.sexButton.imageView.image = [UIImage imageNamed:@"boy"];
        self.sexButton.contentColor = JoyyBlue;
    }
}

- (void)setFriendCount:(uint64_t)friendCount
{
    _friendCount = friendCount;
    NSString *count = [NSString stringWithFormat:@"%llu", friendCount];
    self.friendCountLabel.text = count;

    NSRange range = [count rangeOfString:count];
    [self.friendCountLabel addLinkToURL:[NSURL URLWithString:kFriendURL] withRange:range];
}

- (void)setContactCount:(uint64_t)contactCount
{
    _contactCount = contactCount;
    NSString *count = [NSString stringWithFormat:@"%llu", contactCount];
    self.contactCountLabel.text = count;

    NSRange range = [count rangeOfString:count];
    [self.contactCountLabel addLinkToURL:[NSURL URLWithString:kContactURL] withRange:range];
}

- (void)setWinkCount:(uint64_t)winkCount
{
    _winkCount = winkCount;
    NSString *count = [NSString stringWithFormat:@"%llu", winkCount];
    self.winkCountLabel.text = count;

    NSRange range = [count rangeOfString:count];
    [self.winkCountLabel addLinkToURL:[NSURL URLWithString:kWinkURL] withRange:range];
}

- (void)setAvatarImage:(UIImage *)avatarImage
{
    [self.avatarButton setImage:avatarImage forState:UIControlStateNormal];
}

- (UIButton *)avatarButton
{
    if (!_avatarButton)
    {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.translatesAutoresizingMaskIntoConstraints = NO;
        [button addTarget:self action:@selector(_didTapAvatarButton) forControlEvents:UIControlEventTouchUpInside];
        button.clipsToBounds = YES;
        button.layer.cornerRadius = 40;

        _avatarButton = button;
    }
    return _avatarButton;
}

- (JYButton *)sexButton
{
    if (!_sexButton)
    {
        _sexButton = [JYButton buttonWithFrame:CGRectZero buttonStyle:JYButtonStyleCentralImage shouldMaskImage:YES];
        _sexButton.translatesAutoresizingMaskIntoConstraints = NO;
        _sexButton.foregroundColor = ClearColor;
    }
    return _sexButton;
}

- (TTTAttributedLabel *)usernameLabel
{
    if (!_usernameLabel)
    {
        TTTAttributedLabel *label = [self _propertyLabel];
        label.font = [UIFont systemFontOfSize:kFontSizeCaption];
        label.textAlignment = NSTextAlignmentLeft;
        label.preferredMaxLayoutWidth = 300;

        _usernameLabel = label;
    }
    return _usernameLabel;
}

- (TTTAttributedLabel *)friendCountLabel
{
    if (!_friendCountLabel)
    {
        _friendCountLabel = [self _countLabel];
    }
    return _friendCountLabel;
}

- (TTTAttributedLabel *)friendsLabel
{
    if (!_friendsLabel)
    {
        _friendsLabel = [self _propertyLabel];
        _friendsLabel.text = NSLocalizedString(@"friends", nil);
        NSRange range = [_friendsLabel.text rangeOfString:_friendsLabel.text];
        [_friendsLabel addLinkToURL:[NSURL URLWithString:kFriendURL] withRange:range];
    }
    return _friendsLabel;
}

- (TTTAttributedLabel *)contactCountLabel
{
    if (!_contactCountLabel)
    {
        _contactCountLabel = [self _countLabel];
    }
    return _contactCountLabel;
}

- (TTTAttributedLabel *)contactsLabel
{
    if (!_contactsLabel)
    {
        _contactsLabel = [self _propertyLabel];
        _contactsLabel.text = NSLocalizedString(@"contacts", nil);
        NSRange range = [_contactsLabel.text rangeOfString:_contactsLabel.text];
        [_contactsLabel addLinkToURL:[NSURL URLWithString:kContactURL] withRange:range];
    }
    return _contactsLabel;
}

- (TTTAttributedLabel *)winkCountLabel
{
    if (!_winkCountLabel)
    {
        _winkCountLabel = [self _countLabel];
    }
    return _winkCountLabel;
}

- (TTTAttributedLabel *)winksLabel
{
    if (!_winksLabel)
    {
        _winksLabel = [self _propertyLabel];
        _winksLabel.text = NSLocalizedString(@"winks", nil);
        NSRange range = [_winksLabel.text rangeOfString:_winksLabel.text];
        [_winksLabel addLinkToURL:[NSURL URLWithString:kWinkURL] withRange:range];
    }
    return _winksLabel;
}

- (TTTAttributedLabel *)_countLabel
{
    TTTAttributedLabel *label = [[TTTAttributedLabel alloc] initWithFrame:CGRectZero];
    label.backgroundColor = ClearColor;
    label.delegate = self;
    label.font = [UIFont systemFontOfSize:kFontSizeDetail];
    label.lineBreakMode = NSLineBreakByWordWrapping;
    label.numberOfLines = 0;
    label.preferredMaxLayoutWidth = 80;
    label.textColor = JoyyGray;
    label.textAlignment = NSTextAlignmentCenter;
    label.translatesAutoresizingMaskIntoConstraints = NO;

    UIFont *boldSystemFont = [UIFont boldSystemFontOfSize:14];
    CTFontRef font = CTFontCreateWithName((__bridge CFStringRef)boldSystemFont.fontName, boldSystemFont.pointSize, NULL);
    label.linkAttributes = @{
                             (NSString *)kCTFontAttributeName: (__bridge id)font,
                             (NSString*)kCTForegroundColorAttributeName: (__bridge id)(JoyyBlue.CGColor),
                             (NSString *)kCTUnderlineStyleAttributeName: [NSNumber numberWithBool:NO]
                            };

    label.activeLinkAttributes = @{
                                   (NSString*)kCTForegroundColorAttributeName: (__bridge id)(FlatSand.CGColor),
                                   (NSString *)kCTUnderlineStyleAttributeName: [NSNumber numberWithBool:NO]
                                   };
    return label;
}

- (TTTAttributedLabel *)_propertyLabel
{
    TTTAttributedLabel *label = [[TTTAttributedLabel alloc] initWithFrame:CGRectZero];
    label.backgroundColor = ClearColor;
    label.delegate = self;
    label.font = [UIFont systemFontOfSize:kFontSizeDetail];
    label.lineBreakMode = NSLineBreakByWordWrapping;
    label.numberOfLines = 0;
    label.preferredMaxLayoutWidth = 80;
    label.textColor = JoyyBlack;
    label.textAlignment = NSTextAlignmentCenter;
    label.translatesAutoresizingMaskIntoConstraints = NO;

    label.linkAttributes = @{
                              (NSString*)kCTForegroundColorAttributeName: (__bridge id)(JoyyGray.CGColor),
                              (NSString *)kCTUnderlineStyleAttributeName: [NSNumber numberWithBool:NO]
                            };

    label.activeLinkAttributes = @{
                                   (NSString*)kCTForegroundColorAttributeName: (__bridge id)(FlatSand.CGColor),
                                   (NSString *)kCTUnderlineStyleAttributeName: [NSNumber numberWithBool:NO]
                                 };
    return label;
}

- (void)_didTapAvatarButton
{
    if (self.delegate)
    {
        [self.delegate didTapAvatarOnView:self];
    }
}

#pragma mark -- TTTAttributedLabelDelegate

- (void)attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithURL:(NSURL *)url
{
    if (!self.delegate)
    {
        return;
    }

    if ([kFriendURL isEqualToString:[url absoluteString]])
    {
        [self.delegate didTapFriendLabelOnView:self];
    }
    else if ([kContactURL isEqualToString:[url absoluteString]])
    {
       [self.delegate didTapContactLabelOnView:self];
    }
    else if ([kWinkURL isEqualToString:[url absoluteString]])
    {
        [self.delegate didTapWinkLabelOnView:self];
    }
}

@end
