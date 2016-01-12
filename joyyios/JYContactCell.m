//
//  JYContactCell.m
//  joyyios
//
//  Created by Ping Yang on 1/5/16.
//  Copyright © 2016 Joyy Inc. All rights reserved.
//

#import <TTTAttributedLabel/TTTAttributedLabel.h>

#import "JYContactCell.h"

@interface JYContactCell ()
@property (nonatomic) TTTAttributedLabel *contactNameLabel;
@property (nonatomic) TTTAttributedLabel *phoneNumberLabel;
@end

@implementation JYContactCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        [self.contentView addSubview:self.contactNameLabel];
        [self.contentView addSubview:self.phoneNumberLabel];

        NSDictionary *views = @{
                                @"actionButton": self.actionButton,
                                @"userView": self.userView,
                                @"contactNameLabel": self.contactNameLabel,
                                @"phoneNumberLabel": self.phoneNumberLabel,
                                };

        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[userView]-30-[actionButton(60)]-30-|" options:0 metrics:nil views:views]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-10-[contactNameLabel]-10-[phoneNumberLabel]-(>=10@500)-[actionButton(60)]-30-|" options:0 metrics:nil views:views]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-15-[actionButton(30)]-(>=15@500)-|" options:0 metrics:nil views:views]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-10-[userView(40)][contactNameLabel]-(>=10@500)-|" options:0 metrics:nil views:views]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-10-[userView(40)][phoneNumberLabel]-(>=10@500)-|" options:0 metrics:nil views:views]];

        self.actionButton.textLabel.text = NSLocalizedString(@"connect", nil);
    }
    return self;
}

- (void)setUser:(JYUser *)user
{
    [super setUser:user];
    self.phoneNumberLabel.text = [user.phoneNumber stringValue];
}

- (void)setContactName:(NSString *)contactName
{
    _contactName = contactName;
    self.contactNameLabel.text = contactName;
}

- (TTTAttributedLabel *)contactNameLabel
{
    if (!_contactNameLabel)
    {
        TTTAttributedLabel *label = [[TTTAttributedLabel alloc] initWithFrame:CGRectZero];
        label.translatesAutoresizingMaskIntoConstraints = NO;
        label.font = [UIFont systemFontOfSize:kFontSizeCaption];
        label.backgroundColor = ClearColor;
        label.textColor = JoyyBlue;
        label.lineBreakMode = NSLineBreakByWordWrapping;
        label.numberOfLines = 0;

        _contactNameLabel = label;
    }
    return _contactNameLabel;
}

- (TTTAttributedLabel *)phoneNumberLabel
{
    if (!_phoneNumberLabel)
    {
        TTTAttributedLabel *label = [[TTTAttributedLabel alloc] initWithFrame:CGRectZero];
        label.translatesAutoresizingMaskIntoConstraints = NO;
        label.font = [UIFont systemFontOfSize:kFontSizeCaption];
        label.backgroundColor = ClearColor;
        label.textColor = JoyyGray;
        label.lineBreakMode = NSLineBreakByWordWrapping;
        label.numberOfLines = 0;

        _phoneNumberLabel = label;
    }
    return _phoneNumberLabel;
}

@end
