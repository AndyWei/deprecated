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

+ (CGFloat)cellHeightForText:(NSString *)text
{
    return [JYOrderItemView viewHeightForText:text];
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        self.opaque = YES;
        self.backgroundColor = [UIColor whiteColor];

        CGFloat width = CGRectGetWidth([[UIScreen mainScreen] applicationFrame]);

        self.itemView = [[JYOrderItemView alloc] initWithFrame:CGRectMake(0, 0, width, 100)];
        self.itemView.viewColor = [UIColor whiteColor];
        [self addSubview:self.itemView];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    [self.itemView layoutSubviews];
}

- (void)presentOrder:(NSDictionary *)order
{
    // start date and time
    NSTimeInterval startTime = [[order objectForKey:@"starttime"] integerValue];

    [self.itemView setStartDateTime:[NSDate dateWithTimeIntervalSinceReferenceDate:startTime]];

    // price
    NSUInteger price = [[order objectForKey:@"price"] integerValue];
    self.itemView.priceLabel.text = [NSString stringWithFormat:@"$%tu", price];

    // create time
    [self.itemView setCreateTime:[order objectForKey:@"created_at"]];

    // distance
    CLLocationDegrees lat = [[order objectForKey:@"startpointlat"] doubleValue];
    CLLocationDegrees lon = [[order objectForKey:@"startpointlon"] doubleValue];
    CLLocationCoordinate2D point = CLLocationCoordinate2DMake(lat, lon);
    [self.itemView setDistanceFromPoint:point];

    self.itemView.titleLabel.text = [order objectForKey:@"title"];
    self.itemView.bodyLabel.text = [order objectForKey:@"note"];
    self.itemView.cityLabel.text = [order objectForKey:@"startcity"];
}

- (void)updateCommentsCount:(NSUInteger)count
{
    NSString *comments = NSLocalizedString(@"comments", nil);
    self.itemView.commentsLabel.text = [NSString stringWithFormat:@"%tu %@", count, comments];
}
@end
