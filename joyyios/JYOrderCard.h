//
//  JYOrderCard.h
//  joyyios
//
//  Created by Ping Yang on 4/26/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

@import CoreLocation;

#import "JYBid.h"
#import "JYInvite.h"

@interface JYOrderCard : UIControl

+ (CGFloat)heightForOrder:(JYInvite *)order withAddress:(BOOL)showAddress andBid:(BOOL)showBid;
- (void)presentOrder:(JYInvite *)order withAddress:(BOOL)showAddress andBid:(BOOL)showBid;

@property(nonatomic) BOOL tinyLabelsHidden;
@property(nonatomic, weak) UILabel *commentsLabel;

@end
