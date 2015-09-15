//
//  JYSessionListViewCell.m
//  joyyios
//
//  Created by Ping Yang on 9/3/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

#import <AFNetworking/UIImageView+AFNetworking.h>
#import <TTTAttributedLabel/TTTAttributedLabel.h>

#import "JYSessionListViewCell.h"
#import "JYMessageDateFormatter.h"

static const CGFloat kAvatarImageWidth = 70;
static const CGFloat kTimeLabelWidth = 80;

@interface JYSessionListViewCell ()
@property (nonatomic) JYPerson *person;
@property (nonatomic) TTTAttributedLabel *nameLabel;
@property (nonatomic) TTTAttributedLabel *messageLabel;
@property (nonatomic) TTTAttributedLabel *timeLabel;
@property (nonatomic) UIImageView *avatarView;
@end

@implementation JYSessionListViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        self.opaque = YES;
        self.backgroundColor = JoyyWhite;
    }
    return self;
}

- (void)setContact:(XMPPMessageArchiving_Contact_CoreDataObject *)contact
{
    if (!contact)
    {
        return;
    }

    _contact = contact;
    self.messageLabel.text = [_contact.mostRecentMessageBody messageDisplayString];
    self.timeLabel.text = [[JYMessageDateFormatter sharedInstance] autoStringFromDate:_contact.mostRecentMessageTimestamp];

    NSString *idString = [_contact.bareJidStr personIdString];

    __weak typeof(self) weakSelf = self;
    [[JYDataStore sharedInstance] getPersonWithIdString:idString success:^(JYPerson *person) {

        weakSelf.person = person;
    } failure:^(NSError *error) {
        NSLog(@"Failure: getPersonWithIdString error: %@", error);
    }];
}

- (void)setPerson:(JYPerson *)person
{
    _person = person;

    self.nameLabel.text = person.username;

    // Fetch avatar image via network
    NSURL *url = [NSURL URLWithString:person.avatarURL];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];

    __weak typeof(self) weakSelf = self;
    [self.avatarView setImageWithURLRequest:request
                           placeholderImage:nil
                                    success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                                        weakSelf.person.avatarImage = image;
                                        weakSelf.avatarView.image = image;

                                   } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
                                        NSLog(@"setImageWithURLRequest response = %@", response);
                                   }];
}

- (UIImageView *)avatarView
{
    if (!_avatarView)
    {
        CGFloat y = floor((CGRectGetHeight(self.frame) - kAvatarImageWidth) / 2);
        _avatarView = [[UIImageView alloc] initWithFrame:CGRectMake(20, y, kAvatarImageWidth, kAvatarImageWidth)];
        _avatarView.contentMode = UIViewContentModeScaleAspectFit;
        _avatarView.layer.cornerRadius = kAvatarImageWidth / 2;
        _avatarView.layer.masksToBounds = YES;
        [self addSubview:_avatarView];
    }
    return _avatarView;
}

- (TTTAttributedLabel *)timeLabel
{
    if (!_timeLabel)
    {
        CGFloat x = SCREEN_WIDTH - kTimeLabelWidth;
        CGRect frame = CGRectMake(x, 10, kTimeLabelWidth, 30);
        _timeLabel = [[TTTAttributedLabel alloc] initWithFrame:frame];
        _timeLabel.textInsets = UIEdgeInsetsMake(0, 0, 0, 8);
        _timeLabel.backgroundColor = JoyyWhite;
        _timeLabel.font = [UIFont systemFontOfSize:15];
        _timeLabel.textColor = JoyyGray;
        _timeLabel.textAlignment = NSTextAlignmentRight;
        [self addSubview:_timeLabel];
    }
    return _timeLabel;
}

- (TTTAttributedLabel *)nameLabel
{
    if (!_nameLabel)
    {
        CGFloat x = CGRectGetMaxX(self.avatarView.frame);
        CGFloat width = SCREEN_WIDTH - kTimeLabelWidth - x;
        CGRect frame = CGRectMake(x, 10, width, 30);
        _nameLabel = [[TTTAttributedLabel alloc] initWithFrame:frame];
        _nameLabel.textInsets = UIEdgeInsetsMake(0, 20, 0, 0);
        _nameLabel.backgroundColor = JoyyWhite;
        _nameLabel.font = [UIFont systemFontOfSize:19];
        _nameLabel.textColor = JoyyBlack;
        _nameLabel.textAlignment = NSTextAlignmentLeft;
        [self addSubview:_nameLabel];
    }
    return _nameLabel;
}

- (TTTAttributedLabel *)messageLabel
{
    if (!_messageLabel)
    {
        CGFloat x = CGRectGetMaxX(self.avatarView.frame);
        CGFloat y = CGRectGetMaxY(self.nameLabel.frame);
        CGFloat width = SCREEN_WIDTH - x;
        CGRect frame = CGRectMake(x, y, width, 20);
        _messageLabel = [[TTTAttributedLabel alloc] initWithFrame:frame];
        _messageLabel.textInsets = UIEdgeInsetsMake(0, 20, 0, kMarginRight);
        _messageLabel.backgroundColor = JoyyWhite;
        _messageLabel.font = [UIFont systemFontOfSize:15];
        _messageLabel.textColor = JoyyGray;
        _messageLabel.textAlignment = NSTextAlignmentLeft;
        [self addSubview:_messageLabel];
    }
    return _messageLabel;
}

@end
