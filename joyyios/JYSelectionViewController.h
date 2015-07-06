//
//  JYSelectionViewController.h
//  joyyios
//
//  Created by Ping Yang on 7/5/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "MDCSwipeToChoose.h"

#import "JoyyorCard.h"
#import "Joyyor.h"

@interface JYSelectionViewController : UIViewController <MDCSwipeToChooseDelegate>

@property (nonatomic) Joyyor *currentJoyyor;
@property (nonatomic) JoyyorCard *frontCard;
@property (nonatomic) JoyyorCard *backCard;

@end
