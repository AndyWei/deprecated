//
//  JYOrderCardCell.m
//  joyyor
//
//  Created by Ping Yang on 4/13/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "JYOrderCard.h"
#import "JYOrderCardCell.h"

@interface JYOrderCardCell ()

@property(nonatomic) JYOrderCard *card;

@end


@implementation JYOrderCardCell

+ (CGFloat)cellHeightForOrder:(JYOrder *)order withAddress:(BOOL)showAddress andBid:(BOOL)showBid
{
    return [JYOrderCard cardHeightForOrder:order withAddress:showAddress andBid:showBid];
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        self.opaque = YES;
        _cardColor = self.backgroundColor = JoyyWhite;

        CGFloat width = CGRectGetWidth([[UIScreen mainScreen] applicationFrame]);

        self.card = [[JYOrderCard alloc] initWithFrame:CGRectMake(0, 0, width, 100)];
        self.card.userInteractionEnabled = NO;
        [self addSubview:self.card];
    }
    return self;
}

- (void)setCardColor:(UIColor *)cardColor
{
    if (_cardColor == cardColor)
    {
        return;
    }
    _cardColor = cardColor;
    self.card.backgroundColor = cardColor;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.card.height = self.height;
    [self.card layoutSubviews];
}

- (void)presentOrder:(JYOrder *)order withAddress:(BOOL)showAddress andBid:(BOOL)showBid
{
    [self.card presentOrder:(JYOrder *)order withAddress:showAddress andBid:showBid];
}

- (void)updateCommentsCount:(NSUInteger)count
{
    NSString *comments = NSLocalizedString(@"comments", nil);
    self.card.commentsLabel.text = [NSString stringWithFormat:@"%tu %@", count, comments];
}
@end
