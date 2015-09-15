//
//  JYSignBaseViewController.h
//  joyyios
//
//  Created by Ping Yang on 3/26/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

@class JYButton;

@interface JYSignBaseViewController : UIViewController <UITextFieldDelegate>

@property(nonatomic) UITextField *usernameField;
@property(nonatomic) UITextField *passwordField;
@property(nonatomic) JYButton *signButton;

@end
