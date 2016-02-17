//
//  JYMessageIncomingTextCell.m
//  joyyios
//
//  Created by Ping Yang on 2/16/16.
//  Copyright © 2016 Joyy Inc. All rights reserved.
//

#import "JYMessageIncomingTextCell.h"

@implementation JYMessageIncomingTextCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        NSDictionary *views = @{
                                @"avatarView": self.avatarView,
                                @"contentLabel": self.contentLabel
                                };

        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-10-[avatarView(35)]-10-[contentLabel]-(>=50@500)-|" options:0 metrics:nil views:views]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-10-[avatarView(35)]-(>=0@500)-|" options:0 metrics:nil views:views]];

        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-10-[contentLabel]-(>=0@500)-|" options:0 metrics:nil views:views]];
    }
    return self;
}

@end
