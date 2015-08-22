//
//  JYSignBaseViewController.h
//  joyyios
//
//  Created by Ping Yang on 3/26/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

@class JYFloatLabeledTextField;
@class JYButton;

@interface JYSignBaseViewController : UIViewController <UITextFieldDelegate>

@property(nonatomic, readonly) JYFloatLabeledTextField *emailField;
@property(nonatomic, readonly) JYFloatLabeledTextField *passwordField;
@property(nonatomic, readonly) JYButton *signButton;


- (BOOL)inputCheckPassed;

/*
 * Subclassing:
 */
- (void)signButtonPressed; // Override to handle signButton touched event. Don't call super.

@end
