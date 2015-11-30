//
//  JYUserCard.h
//  joyyios
//
//  Created by Ping Yang on 7/5/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

#import "MDCSwipeToChoose.h"

@interface JYUserCard : MDCSwipeToChooseView

- (instancetype)initWithFrame:(CGRect)frame options:(MDCSwipeToChooseViewOptions *)options;

@property (nonatomic) JYUser *user;

@end
