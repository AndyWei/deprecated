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

        self.topLabel = [[UILabel alloc] initWithFrame:CGRectMake(60, 10, 315, 25)];
        self.topLabel.textColor = FlatBlack;
        self.topLabel.font = [UIFont systemFontOfSize:18.0f];
        self.topLabel.backgroundColor = FlatWhite;
        [self addSubview:self.topLabel];

        self.bottomLabel = [[UILabel alloc] initWithFrame:CGRectMake(60, 35, 315, 20)];
        self.bottomLabel.textColor = FlatGrayDark;
        self.bottomLabel.font = [UIFont systemFontOfSize:15.0f];
        self.bottomLabel.backgroundColor = FlatWhite;
        [self addSubview:self.bottomLabel];

        self.iconView = [[UIImageView alloc] initWithFrame:CGRectMake(20, 15, 25, 25)];
        self.iconView.backgroundColor = FlatWhite;
        [self addSubview:self.iconView];
    }
    return self;
}

@end
