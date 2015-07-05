//
//  JYOrderViewCell.m
//  joyyios
//
//  Created by Ping Yang on 6/21/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "JYButton.h"
#import "JYOrderControl.h"
#import "JYOrderViewCell.h"


@interface JYOrderViewCell ()

@property(nonatomic, weak) JYOrderControl *orderControl;

@end


@implementation JYOrderViewCell

+ (CGFloat)heightForOrder:(JYInvite *)order
{
    return [JYOrderControl heightForOrder:order];
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        self.opaque = YES;
        [self _createOrderControl];
        _color = self.backgroundColor = self.orderControl.color = JoyyWhite;
    }
    return self;
}

- (void)_createOrderControl
{
    CGFloat width = CGRectGetWidth([[UIScreen mainScreen] applicationFrame]);

    JYOrderControl *orderControl = [[JYOrderControl alloc] initWithFrame:CGRectMake(0, 0, width, self.height)];
    self.orderControl = orderControl;

    [self addSubview:self.orderControl];
}


- (void)setColor:(UIColor *)color
{
    if (_color == color)
    {
        return;
    }
    _color = color;
    self.backgroundColor = self.orderControl.color = color;
}

- (void)setOrder:(JYInvite *)order
{
    _order = order;
    self.orderControl.order = order;
    self.orderControl.height = self.height; // Removing this statement will cause the payButton not work
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    [self.orderControl layoutSubviews];
}

@end
