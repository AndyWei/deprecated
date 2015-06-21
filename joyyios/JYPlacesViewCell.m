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

        UILabel *topLabel = [[UILabel alloc] initWithFrame:CGRectMake(50, 8, 315, 25)];
        topLabel.textColor = FlatBlack;
        topLabel.font = [UIFont boldSystemFontOfSize:17];
        topLabel.backgroundColor = FlatWhite;
        self.topLabel = topLabel;
        [self addSubview:self.topLabel];

        UILabel *bottomLabel = [[UILabel alloc] initWithFrame:CGRectMake(50, 33, 315, 20)];
        bottomLabel.textColor = FlatGrayDark;
        bottomLabel.font = [UIFont systemFontOfSize:14];
        bottomLabel.backgroundColor = FlatWhite;
        self.bottomLabel = bottomLabel;
        [self addSubview:self.bottomLabel];

        UIImageView *iconView = [[UIImageView alloc] initWithFrame:CGRectMake(14, 20, 22, 22)];
        iconView.backgroundColor = FlatWhite;
        iconView.alpha = 0.5;
        self.iconView = iconView;
        [self addSubview:self.iconView];
    }
    return self;
}

@end
