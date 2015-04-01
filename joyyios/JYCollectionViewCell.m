//
//  JYCollectionViewCell.m
//  joyyios
//
//  Created by Ping Yang on 3/31/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "JYCollectionViewCell.h"

@implementation JYCollectionViewCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.contentView.opaque = YES;
        self.contentView.backgroundColor = FlatSkyBlueDark;

        _imageView = [UIImageView new];
        _imageView.clipsToBounds = YES;
        _imageView.contentMode = UIViewContentModeScaleAspectFill;
        _imageView.opaque = YES;
        [self.contentView addSubview:_imageView];

        _label = [UILabel new];
        _label.backgroundColor = ClearColor;
        _label.opaque = YES;
        _label.font = [UIFont boldSystemFontOfSize:kServiceCategoryCellFontSize];
        _label.textColor = FlatWhite;
        _label.textAlignment = NSTextAlignmentCenter;
        [self.contentView addSubview:_label];
    }
    return self;
}

@end
