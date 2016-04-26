//
//  JYWinkCell.m
//  joyyios
//
//  Created by Ping Yang on 12/23/15.
//  Copyright © 2015 Joyy Inc. All rights reserved.
//

#import "JYWinkCell.h"

@interface JYWinkCell ()
@end

@implementation JYWinkCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        NSDictionary *views = @{
                                @"actionButton": self.actionButton,
                                @"userView": self.userView
                                };

        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[userView]-30-[actionButton(80)]-10-|" options:0 metrics:nil views:views]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-15-[actionButton(30)]-(>=15@500)-|" options:0 metrics:nil views:views]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-10-[userView(40)]-(>=10@500)-|" options:0 metrics:nil views:views]];

        self.actionButton.textLabel.text = NSLocalizedString(@"accept", nil);
    }
    return self;
}

@end
