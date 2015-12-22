//
//  JYJellyView.h
//  joyyios
//
//  Created by Ping Yang on 12/18/15.
//  Copyright © 2015 Joyy Inc. All rights reserved.
//

@interface JYJellyView : UIView

- (instancetype)initWithFrame:(CGRect)frame;
- (void)startSnap;
- (void)stopSnap;
- (void)startRotateBallView;
- (void)stopRotateBallView;
- (void)startJellyBounce;
- (void)stopJellyBounce;

@property (nonatomic) BOOL isRefreshing;
@property (nonatomic) CGFloat contentOffsetY;
@end
