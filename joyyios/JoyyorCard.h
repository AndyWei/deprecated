//
//  JYSelectionView.h
//  joyyios
//
//  Created by Ping Yang on 7/5/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "MDCSwipeToChoose.h"

@class Joyyor;

@interface JoyyorCard : MDCSwipeToChooseView

@property (nonatomic, readonly) Joyyor *joyyor;

- (instancetype)initWithFrame:(CGRect)frame
                       joyyor:(Joyyor *)joyyor
                      options:(MDCSwipeToChooseViewOptions *)options;

@end
