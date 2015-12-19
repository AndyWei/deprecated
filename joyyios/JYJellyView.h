//
//  JYJellyView.h
//  joyyios
//
//  Created by Ping Yang on 12/18/15.
//  Copyright © 2015 Joyy Inc. All rights reserved.
//


@interface JYJellyView : UIView

@property (nonatomic) BOOL isLoading;
@property (nonatomic) CGFloat controlPointOffset;
@property (nonatomic) CGFloat yOffset;
@property (nonatomic) CGRect userFrame;
@property (nonatomic) UIView *controlPoint;

@end
