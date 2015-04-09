//
//  JYPlacesViewCell.m
//  joyyios
//
//  Created by Ping Yang on 4/8/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "JYPlacesViewCell.h"

@implementation JYPlacesViewCell


- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        self.backgroundColor = FlatWhite;

        self.topLabel = [[UILabel alloc] initWithFrame:CGRectMake(50, 8, 315, 25)];
        self.topLabel.textColor = FlatBlack;
        self.topLabel.font = [UIFont fontWithName:@"AvenirNext-Medium" size:17.0f];
        self.topLabel.backgroundColor = FlatWhite;
        [self addSubview:self.topLabel];

        self.bottomLabel = [[UILabel alloc] initWithFrame:CGRectMake(50, 33, 315, 20)];
        self.bottomLabel.textColor = FlatGrayDark;
        self.bottomLabel.font = [UIFont fontWithName:@"AvenirNext-Regular" size:14.0f];
        self.bottomLabel.backgroundColor = FlatWhite;
        [self addSubview:self.bottomLabel];

        self.iconView = [[UIImageView alloc] initWithFrame:CGRectMake(14, 20, 22, 22)];
        self.iconView.backgroundColor = FlatWhite;
        [self addSubview:self.iconView];
    }
    return self;
}

@end
