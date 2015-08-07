//
//  JYPersonCard.h
//  joyyios
//
//  Created by Ping Yang on 7/5/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "MDCSwipeToChoose.h"

@class JYPerson;

@interface JYPersonCard : MDCSwipeToChooseView

@property (nonatomic, readonly) JYPerson *person;

- (instancetype)initWithFrame:(CGRect)frame
                       person:(JYPerson *)person
                      options:(MDCSwipeToChooseViewOptions *)options;

@end
