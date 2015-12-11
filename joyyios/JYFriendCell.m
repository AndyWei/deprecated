//
//  JYFriendCell.m
//  joyyios
//
//  Created by Ping Yang on 12/10/15.
//  Copyright © 2015 Joyy Inc. All rights reserved.
//

#import "JYFriend.h"
#import "JYFriendCell.h"
#import "JYFriendView.h"

@interface JYFriendCell ()
@property (nonatomic) JYFriendView *friendView;
@end

@implementation JYFriendCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.contentView.backgroundColor = JoyyWhitePure;

        [self.contentView addSubview:self.friendView];

        NSDictionary *views = @{
                                @"friendView": self.friendView
                                };

        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[friendView]-0-|" options:0 metrics:nil views:views]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[friendView]-0-|" options:0 metrics:nil views:views]];
    }
    return self;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    self.user = nil;
}

- (void)setUser:(JYFriend *)user
{
    _user = user;
    self.friendView.user = user;
}

- (JYFriendView *)friendView
{
    if (!_friendView)
    {
        _friendView = [[JYFriendView alloc] init];
    }
    return _friendView;
}

@end
