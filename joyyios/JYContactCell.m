//
//  JYContactCell.m
//  joyyios
//
//  Created by Ping Yang on 1/5/16.
//  Copyright © 2016 Joyy Inc. All rights reserved.
//

#import "JYContactCell.h"

@implementation JYContactCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        NSDictionary *views = @{
                                @"actionButton": self.actionButton,
                                @"userView": self.userView
                                };

        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[userView]-30-[actionButton(60)]-30-|" options:0 metrics:nil views:views]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-15-[actionButton(30)]-(>=15@500)-|" options:0 metrics:nil views:views]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-10-[userView(40)]-(>=10@500)-|" options:0 metrics:nil views:views]];

        self.actionButton.textLabel.text = NSLocalizedString(@"connects", nil);
    }
    return self;
}

@end
