//
//  JYSignBaseViewController.h
//  joyyios
//
//  Created by Ping Yang on 3/26/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

@class JYFloatLabeledTextField;
@class MRoundedButton;

@interface JYSignBaseViewController : UIViewController <UITextFieldDelegate>

@property(nonatomic, strong, readonly) JYFloatLabeledTextField *emailField;
@property(nonatomic, strong, readonly) JYFloatLabeledTextField *passwordField;
@property(nonatomic, strong, readonly) MRoundedButton *signButton;

/*
 * Subclassing:
 */
- (void)signButtonTouched; // Override to handle signButton touched event. Don't call super.

@end
