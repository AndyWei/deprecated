//
//  JYOrderViewCell.m
//  joyyor
//
//  Created by Ping Yang on 4/13/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "JYOrderItemView.h"
#import "JYOrderViewCell.h"

@interface JYOrderViewCell ()

@property(nonatomic) JYOrderItemView *itemView;

@end


@implementation JYOrderViewCell

+ (CGFloat)cellHeightForOrder:(JYOrder *)order
{
    return [JYOrderItemView viewHeightForOrder:order];
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        self.opaque = YES;
        self.backgroundColor = JoyyWhite;

        CGFloat width = CGRectGetWidth([[UIScreen mainScreen] applicationFrame]);

        self.itemView = [[JYOrderItemView alloc] initWithFrame:CGRectMake(0, 0, width, 100)];
        self.itemView.bidLabelHidden = YES;
        self.itemView.userInteractionEnabled = NO;
        [self addSubview:self.itemView];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.itemView.height = self.height;
    [self.itemView layoutSubviews];
}

- (void)presentOrder:(JYOrder *)order
{
    [self.itemView presentOrder:order];
}

- (void)presentBiddedOrder:(JYOrder *)order
{
    [self.itemView presentBiddedOrder:order];
}

- (void)updateCommentsCount:(NSUInteger)count
{
    NSString *comments = NSLocalizedString(@"comments", nil);
    self.itemView.commentsLabel.text = [NSString stringWithFormat:@"%tu %@", count, comments];
}
@end
