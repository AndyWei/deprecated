//
//  JYMessageIncomingMediaCell.m
//  joyyios
//
//  Created by Ping Yang on 2/16/16.
//  Copyright © 2016 Joyy Inc. All rights reserved.
//

#import "JYMessageIncomingMediaCell.h"

@implementation JYMessageIncomingMediaCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        NSDictionary *views = @{
                                @"topLabel": self.topLabel,
                                @"avatarView": self.avatarView,
                                @"mediaContainerView": self.mediaContainerView
                                };

        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-10-[avatarView(35)]-10-[mediaContainerView]-(>=50@500)-|" options:0 metrics:nil views:views]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-10-[topLabel]-10-[avatarView(35)]-(>=10@500)-|" options:0 metrics:nil views:views]];

        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-10-[topLabel]-10-[mediaContainerView]-(>=10@500)-|" options:0 metrics:nil views:views]];
    }
    return self;
}

@end
