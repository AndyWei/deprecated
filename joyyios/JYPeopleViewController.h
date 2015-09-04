//
//  JYPeopleViewController.h
//  joyyios
//
//  Created by Ping Yang on 7/5/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

#import "MDCSwipeToChoose.h"
#import "JYPersonCard.h"

@interface JYPeopleViewController : UIViewController <MDCSwipeToChooseDelegate>

@property (nonatomic) JYPerson *currentPerson;
@property (nonatomic) JYPersonCard *frontCard;
@property (nonatomic) JYPersonCard *backCard;

@end
