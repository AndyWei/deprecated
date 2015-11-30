//
//  JYUserViewController.h
//  joyyios
//
//  Created by Ping Yang on 7/5/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

#import "MDCSwipeToChoose.h"
#import "JYUserCard.h"

@interface JYUserViewController : UIViewController

@property (nonatomic) JYUser *currentUser;
@property (nonatomic) JYUserCard *frontCard;
@property (nonatomic) JYUserCard *backCard;

@end
