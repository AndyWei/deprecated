//
//  JYContactCell.m
//  joyyios
//
//  Created by Ping Yang on 1/5/16.
//  Copyright © 2016 Joyy Inc. All rights reserved.
//

#import <TTTAttributedLabel/TTTAttributedLabel.h>
#import <libPhoneNumber-iOS/NBPhoneNumberUtil.h>

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

        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[userView]-10-[actionButton(130)]-10-|" options:0 metrics:nil views:views]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-10-[contactNameLabel]-10-[phoneNumberLabel]-(>=10@500)-|" options:0 metrics:nil views:views]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-20-[actionButton(30)]-(>=10@500)-|" options:0 metrics:nil views:views]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-10-[userView(40)][contactNameLabel]-(>=10@500)-|" options:0 metrics:nil views:views]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-10-[userView(40)][phoneNumberLabel]-(>=10@500)-|" options:0 metrics:nil views:views]];

        self.actionButton.textLabel.text = NSLocalizedString(@"connect", nil);
        self.userView.hideDetail = YES;
    }
    return self;
}

- (void)setUser:(JYUser *)user
{
    [super setUser:user];

    NSString *e164 = [NSString stringWithFormat:@"+%@", [user.phoneNumber stringValue]];
    NBPhoneNumberUtil *phoneUtil = [NBPhoneNumberUtil new];

    NSError *error = nil;
    NBPhoneNumber *number = [phoneUtil parse:e164 defaultRegion:nil error:&error];
    self.phoneNumberLabel.text = [phoneUtil format:number numberFormat:NBEPhoneNumberFormatINTERNATIONAL error:&error];
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
        label.font = [UIFont systemFontOfSize:kFontSizeDetail];
        label.backgroundColor = ClearColor;
        label.textColor = JoyyGray;
        label.textAlignment = NSTextAlignmentRight;
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
        label.font = [UIFont systemFontOfSize:kFontSizeDetail];
        label.backgroundColor = ClearColor;
        label.textColor = JoyyGray;
        label.textAlignment = NSTextAlignmentRight;
        label.lineBreakMode = NSLineBreakByWordWrapping;
        label.numberOfLines = 0;

        _phoneNumberLabel = label;
    }
    return _phoneNumberLabel;
}

@end
