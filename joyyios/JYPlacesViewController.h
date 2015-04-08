//
//  JYPlacesViewController.h
//  joyyios
//
//  Created by Ping Yang on 4/8/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "LPGoogleFunctions.h"

@interface JYPlacesViewController : UIViewController <LPGoogleFunctionsDelegate, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate>

@property (nonatomic) UIImage *searchBarImage;

@end
