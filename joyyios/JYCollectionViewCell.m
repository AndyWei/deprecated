//
//  JYCollectionViewCell.m
//  joyyios
//
//  Created by Ping Yang on 3/31/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "JYCollectionViewCell.h"

@implementation JYCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.contentView.opaque = YES;
        self.contentView.backgroundColor = FlatSkyBlueDark;

        self.imageView = [UIImageView new];
        self.imageView.clipsToBounds = YES;
        self.imageView.contentMode = UIViewContentModeScaleAspectFill;
        self.imageView.opaque = YES;
        [self.contentView addSubview:_imageView];

        self.label = [UILabel new];
        self.label.backgroundColor = ClearColor;
        self.label.opaque = YES;
        self.label.font = [UIFont boldSystemFontOfSize:kServiceCategoryCellFontSize];
        self.label.textColor = FlatWhite;
        self.label.textAlignment = NSTextAlignmentCenter;
        [self.contentView addSubview:self.label];
    }
    return self;
}

@end
