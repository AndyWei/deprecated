//
//  JYPersonCard.h
//  joyyios
//
//  Created by Ping Yang on 7/5/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

#import "MDCSwipeToChoose.h"

@class JYPerson;
@class JYPersonCard;

@protocol JYPersonCardDelegate <NSObject>

@optional
- (void)cardDidLoadImage:(JYPersonCard *)card;

@end

@interface JYPersonCard : MDCSwipeToChooseView

- (instancetype)initWithFrame:(CGRect)frame options:(MDCSwipeToChooseViewOptions *)options;

@property (nonatomic) JYPerson *person;
@property (nonatomic, weak) id<JYPersonCardDelegate> delegate;

@end
