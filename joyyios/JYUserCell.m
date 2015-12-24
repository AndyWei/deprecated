//
//  JYUserCell.m
//  joyyios
//
//  Created by Ping Yang on 12/10/15.
//  Copyright © 2015 Joyy Inc. All rights reserved.
//

#import "JYUser.h"
#import "JYUserCell.h"
#import "JYUserView.h"

@interface JYUserCell ()
@property (nonatomic) JYUserView *userView;
@end

@implementation JYUserCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.contentView.backgroundColor = JoyyWhitePure;

        [self.contentView addSubview:self.userView];

        NSDictionary *views = @{
                                @"userView": self.userView
                                };

        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[userView]-0-|" options:0 metrics:nil views:views]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[userView]-0-|" options:0 metrics:nil views:views]];
    }
    return self;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    self.user = nil;
}

- (void)setUser:(JYUser *)user
{
    _user = user;
    self.userView.user = user;
}

- (JYUserView *)userView
{
    if (!_userView)
    {
        _userView = [[JYUserView alloc] init];
    }
    return _userView;
}

@end
