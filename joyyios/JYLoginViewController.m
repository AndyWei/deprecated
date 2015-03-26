//
//  JYLoginViewController.m
//  joyy
//
//  Created by Ping Yang on 3/26/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//


#import "JVFloatLabeledTextField.h"
#import "JVFloatLabeledTextView.h"
#import "JYLoginViewController.h"


@interface JYLoginViewController ()

@end

@implementation JYLoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    CGFloat topOffset = 0;

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 70000
    [self.view setTintColor:[UIColor blueColor]];

    topOffset = ([[UIApplication sharedApplication] statusBarFrame].size.height
                 + self.navigationController.navigationBar.frame.size.height);
#endif

    UIColor *floatingLabelColor = [UIColor brownColor];

    JVFloatLabeledTextField *titleField = [[JVFloatLabeledTextField alloc] initWithFrame:
                                           CGRectMake(kJVFieldHMargin,
                                                      topOffset,
                                                      self.view.frame.size.width - 2 * kJVFieldHMargin,
                                                      kJVFieldHeight)];
    titleField.attributedPlaceholder =
    [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Title", @"")
                                    attributes:@{NSForegroundColorAttributeName: [UIColor darkGrayColor]}];
    titleField.font = [UIFont systemFontOfSize:kJVFieldFontSize];
    titleField.floatingLabel.font = [UIFont boldSystemFontOfSize:kJVFieldFloatingLabelFontSize];
    titleField.floatingLabelTextColor = floatingLabelColor;
    titleField.clearButtonMode = UITextFieldViewModeWhileEditing;
    //    UIView *leftView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 30.0f, 30.0f)];
    //    titleField.leftView = leftView;
    //    titleField.leftViewMode = UITextFieldViewModeAlways;
    [self.view addSubview:titleField];

    UIView *div1 = [UIView new];
    div1.frame = CGRectMake(kJVFieldHMargin, titleField.frame.origin.y + titleField.frame.size.height,
                            self.view.frame.size.width - 2 * kJVFieldHMargin, 1.0f);
    div1.backgroundColor = [[UIColor lightGrayColor] colorWithAlphaComponent:0.3f];
    [self.view addSubview:div1];

    JVFloatLabeledTextField *priceField = [[JVFloatLabeledTextField alloc] initWithFrame:
                                           CGRectMake(kJVFieldHMargin,
                                                      div1.frame.origin.y + div1.frame.size.height,
                                                      80.0f,
                                                      kJVFieldHeight)];
    priceField.attributedPlaceholder =
    [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Price", @"")
                                    attributes:@{NSForegroundColorAttributeName: [UIColor darkGrayColor]}];
    priceField.font = [UIFont systemFontOfSize:kJVFieldFontSize];
    priceField.floatingLabel.font = [UIFont boldSystemFontOfSize:kJVFieldFloatingLabelFontSize];
    priceField.floatingLabelTextColor = floatingLabelColor;
    [self.view addSubview:priceField];

    UIView *div2 = [UIView new];
    div2.frame = CGRectMake(kJVFieldHMargin + priceField.frame.size.width,
                            titleField.frame.origin.y + titleField.frame.size.height,
                            1.0f, kJVFieldHeight);
    div2.backgroundColor = [[UIColor lightGrayColor] colorWithAlphaComponent:0.3f];
    [self.view addSubview:div2];

    JVFloatLabeledTextField *locationField =
    [[JVFloatLabeledTextField alloc] initWithFrame:
     CGRectMake(kJVFieldHMargin + kJVFieldHMargin + priceField.frame.size.width + 1.0f,
                div1.frame.origin.y + div1.frame.size.height,
                self.view.frame.size.width - 3*kJVFieldHMargin - priceField.frame.size.width - 1.0f,
                kJVFieldHeight)];

    locationField.attributedPlaceholder =
    [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Specific Location (optional)", @"")
                                    attributes:@{NSForegroundColorAttributeName: [UIColor darkGrayColor]}];
    locationField.font = [UIFont systemFontOfSize:kJVFieldFontSize];
    locationField.floatingLabel.font = [UIFont boldSystemFontOfSize:kJVFieldFloatingLabelFontSize];
    locationField.floatingLabelTextColor = floatingLabelColor;
    [self.view addSubview:locationField];

    UIView *div3 = [UIView new];
    div3.frame = CGRectMake(kJVFieldHMargin, priceField.frame.origin.y + priceField.frame.size.height,
                            self.view.frame.size.width - 2*kJVFieldHMargin, 1.0f);
    div3.backgroundColor = [[UIColor lightGrayColor] colorWithAlphaComponent:0.3f];
    [self.view addSubview:div3];

    JVFloatLabeledTextView *descriptionField =
    [[JVFloatLabeledTextView alloc] initWithFrame:CGRectMake(kJVFieldHMargin,
                                                             div3.frame.origin.y + div3.frame.size.height,
                                                             self.view.frame.size.width - 2*kJVFieldHMargin,
                                                             kJVFieldHeight*3)];
    descriptionField.placeholder = NSLocalizedString(@"Description", @"");
    descriptionField.placeholderTextColor = [UIColor darkGrayColor];
    descriptionField.font = [UIFont systemFontOfSize:kJVFieldFontSize];
    descriptionField.floatingLabel.font = [UIFont boldSystemFontOfSize:kJVFieldFloatingLabelFontSize];
    descriptionField.floatingLabelTextColor = floatingLabelColor;
    [self.view addSubview:descriptionField];

    [titleField becomeFirstResponder];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
