//
//  JYMenuViewCell.m
//  joyyios
//
//  Created by Ping Yang on 7/1/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "JYMenuViewCell.h"

@interface JYMenuViewCell ()

@property(nonatomic, weak) UILabel *label;

@end


static CGFloat kCellHeight = 50;


@implementation JYMenuViewCell

+ (CGFloat)height
{
    return kCellHeight;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        self.backgroundColor = FlatBlack;
        [self _createLabel];
    }
    return self;
}

- (void)_createLabel
{
    CGFloat width = CGRectGetWidth(self.frame) - kMarginLeft;
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(kMarginLeft, 0, width, kCellHeight)];
    label.font = [UIFont systemFontOfSize:20];
    label.backgroundColor = FlatBlack;
    label.textColor = FlatWhite;
    label.textAlignment = NSTextAlignmentLeft;

    self.label = label;
    [self addSubview:label];
}

- (void)setText:(NSString *)text
{
    self.label.text = text;
}

@end
