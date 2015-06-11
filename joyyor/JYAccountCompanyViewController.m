//
//  JYAccountCompanyViewController.m
//  joyyor
//
//  Created by Andy Wei on 6/2/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import <AFNetworking/AFNetworking.h>
#import <KVNProgress/KVNProgress.h>
#import <RKDropdownAlert/RKDropdownAlert.h>
#import <XLForm/XLForm.h>

#import "JYAccountCompanyViewController.h"
#import "JYFixedLengthRowValidator.h"
#import "JYFloatLabeledTextFieldCell.h"
#import "JYButton.h"
#import "JYUser.h"

@interface JYAccountCompanyViewController ()

@end

@implementation JYAccountCompanyViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = NSLocalizedString(@"Company Account", nil);

    UIBarButtonItem *barButton =
    [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Submit", nil) style:UIBarButtonItemStylePlain target:self action:@selector(_submit)];
    self.navigationItem.rightBarButtonItem = barButton;

    [self _createForm];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)_createForm
{
    XLFormDescriptor *form = nil;
    XLFormSectionDescriptor *section = nil;
    XLFormRowDescriptor *row = nil;
    JYFixedLengthRowValidator *validator = nil;
    NSString *message = nil;

    form = [XLFormDescriptor formDescriptor];
    form.assignFirstResponderOnShow = YES;

    // Personal Info
    section = [XLFormSectionDescriptor formSectionWithTitle:NSLocalizedString(@"Company Information", nil)];
    [form addFormSection:section];
    row = [XLFormRowDescriptor formRowDescriptorWithTag:@"biz_name" rowType:XLFormRowDescriptorTypeFloatLabeledName title:NSLocalizedString(@"Business Name", nil)];
    row.required = YES;
    [section addFormRow:row];

    row = [XLFormRowDescriptor formRowDescriptorWithTag:@"biz_tax_id" rowType:XLFormRowDescriptorTypeFloatLabeledInteger title:NSLocalizedString(@"EIN (Employer Identification Number)", nil)];
    row.required = YES;
    [section addFormRow:row];

    // Company Address
    section = [XLFormSectionDescriptor formSectionWithTitle:NSLocalizedString(@"Company Address", nil)];
    [form addFormSection:section];
    row = [XLFormRowDescriptor formRowDescriptorWithTag:@"biz_line1" rowType:XLFormRowDescriptorTypeFloatLabeledText title:NSLocalizedString(@"Address line 1", nil)];
    row.required = YES;
    [section addFormRow:row];

    row = [XLFormRowDescriptor formRowDescriptorWithTag:@"biz_line2" rowType:XLFormRowDescriptorTypeFloatLabeledText title:NSLocalizedString(@"Address line 2 (optional)", nil)];
    [section addFormRow:row];

    row = [XLFormRowDescriptor formRowDescriptorWithTag:@"biz_city" rowType:XLFormRowDescriptorTypeFloatLabeledName title:NSLocalizedString(@"City", nil)];
    row.required = YES;
    row.value = [NSDate dateWithTimeIntervalSince1970:0];
    [section addFormRow:row];

    row = [XLFormRowDescriptor formRowDescriptorWithTag:@"biz_state" rowType:XLFormRowDescriptorTypeFloatLabeledName title:NSLocalizedString(@"State", nil)];
    row.required = YES;
    [section addFormRow:row];

    row = [XLFormRowDescriptor formRowDescriptorWithTag:@"biz_zipcode" rowType:XLFormRowDescriptorTypeFloatLabeledZipcode title:NSLocalizedString(@"Zip Code (5 digits)", nil)];
    row.required = YES;
    message = NSLocalizedString(@"Zip Code should contain only 5 digits", nil);
    validator = [[JYFixedLengthRowValidator alloc] initWithMsg:message andFixedLength:5];
    [row addValidator:validator];
    [section addFormRow:row];

    // Representative Personal Information
    section = [XLFormSectionDescriptor formSectionWithTitle:NSLocalizedString(@"Company Representative Personal Information", nil)];
    [form addFormSection:section];
    row = [XLFormRowDescriptor formRowDescriptorWithTag:@"first_name" rowType:XLFormRowDescriptorTypeFloatLabeledName title:NSLocalizedString(@"First Name", nil)];
    row.required = YES;
    [section addFormRow:row];

    row = [XLFormRowDescriptor formRowDescriptorWithTag:@"last_name" rowType:XLFormRowDescriptorTypeFloatLabeledName title:NSLocalizedString(@"Last Name", nil)];
    row.required = YES;
    [section addFormRow:row];

    row = [XLFormRowDescriptor formRowDescriptorWithTag:@"dob" rowType:XLFormRowDescriptorTypeDate title:NSLocalizedString(@"Date of Birth", nil)];
    NSString* str = @"01/01/1980";
    NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"MM/dd/yyyy"];
    row.value = [formatter dateFromString:str];
    [section addFormRow:row];

    row = [XLFormRowDescriptor formRowDescriptorWithTag:@"personal_id" rowType:XLFormRowDescriptorTypeFloatLabeledSSN title:NSLocalizedString(@"Social Security Number (9 digits)", nil)];
    row.required = YES;
    message = NSLocalizedString(@"Social Security Number should contains 9 digits", nil);
    validator = [[JYFixedLengthRowValidator alloc] initWithMsg:message andFixedLength:9];
    [row addValidator:validator];
    [section addFormRow:row];

    // Address
    section = [XLFormSectionDescriptor formSectionWithTitle:NSLocalizedString(@"Company Representative Address", nil)];
    [form addFormSection:section];
    row = [XLFormRowDescriptor formRowDescriptorWithTag:@"line1" rowType:XLFormRowDescriptorTypeFloatLabeledText title:NSLocalizedString(@"Address line 1", nil)];
    row.required = YES;
    [section addFormRow:row];

    row = [XLFormRowDescriptor formRowDescriptorWithTag:@"line2" rowType:XLFormRowDescriptorTypeFloatLabeledText title:NSLocalizedString(@"Address line 2 (optional)", nil)];
    [section addFormRow:row];

    row = [XLFormRowDescriptor formRowDescriptorWithTag:@"city" rowType:XLFormRowDescriptorTypeFloatLabeledName title:NSLocalizedString(@"City", nil)];
    row.required = YES;
    row.value = [NSDate dateWithTimeIntervalSince1970:0];
    [section addFormRow:row];

    row = [XLFormRowDescriptor formRowDescriptorWithTag:@"state" rowType:XLFormRowDescriptorTypeFloatLabeledName title:NSLocalizedString(@"State", nil)];
    row.required = YES;
    [section addFormRow:row];

    row = [XLFormRowDescriptor formRowDescriptorWithTag:@"zipcode" rowType:XLFormRowDescriptorTypeFloatLabeledZipcode title:NSLocalizedString(@"Zip Code (5 digits)", nil)];
    row.required = YES;
    message = NSLocalizedString(@"Zip Code should contain only 5 digits", nil);
    validator = [[JYFixedLengthRowValidator alloc] initWithMsg:message andFixedLength:5];
    [row addValidator:validator];
    [section addFormRow:row];

    // Bank Account
    section = [XLFormSectionDescriptor formSectionWithTitle:NSLocalizedString(@"Company Bank Information", nil)];
    [form addFormSection:section];
    row = [XLFormRowDescriptor formRowDescriptorWithTag:@"routing_number" rowType:XLFormRowDescriptorTypeFloatLabeledInteger title:NSLocalizedString(@"Routing Number (9 digits)", nil)];
    row.required = YES;
    message = NSLocalizedString(@"Routing Number should contain only 9 digits", nil);
    validator = [[JYFixedLengthRowValidator alloc] initWithMsg:message andFixedLength:9];
    [row addValidator:validator];
    [section addFormRow:row];

    row = [XLFormRowDescriptor formRowDescriptorWithTag:@"account_number" rowType:XLFormRowDescriptorTypeFloatLabeledInteger title:NSLocalizedString(@"Account Number", nil)];
    row.required = YES;
    [section addFormRow:row];

    self.form = form;
}

- (NSDictionary *)_httpParameters
{
    NSMutableDictionary *parameters = (NSMutableDictionary *)[self.form httpParameters:self];
    // Remove items
    [parameters removeObjectForKey:@"dob"];
    [parameters removeObjectForKey:@"line2"];
    [parameters removeObjectForKey:@"biz_line2"];

    // Add items
    id line2 = [self.formValues objectForKey:@"line2"];
    if (![line2 isKindOfClass:[NSNull class]])
    {
        [parameters setValue:[self.formValues valueForKey:@"line2"] forKey:@"line2"];
    }

    line2 = [self.formValues objectForKey:@"biz_line2"];
    if (![line2 isKindOfClass:[NSNull class]])
    {
        [parameters setValue:[self.formValues valueForKey:@"biz_line2"] forKey:@"biz_line2"];
    }

    NSDate *dob = [self.formValues valueForKey:@"dob"];
    NSDateComponents *dobComponents = [[NSCalendar currentCalendar] components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:dob];

    [parameters setValue:@(dobComponents.year) forKey:@"year"];
    [parameters setValue:@(dobComponents.month) forKey:@"month"];
    [parameters setValue:@(dobComponents.day) forKey:@"day"];

    return parameters;
}

- (BOOL)_formFilled
{
    NSArray *validationErrors = [self formValidationErrors];
    if (validationErrors == NULL || validationErrors.count == 0)
    {
        return YES;

    }

    [self _showFormValidationError:[validationErrors firstObject]];
    return NO;
}

- (void)_showFormValidationError:(NSError *)error
{
    UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(kErrorTitle, nil) message:error.localizedDescription delegate:self cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
    [alertView show];
}

- (void)_submit
{
    if ([self _formFilled])
    {
        [self _submitAccountInfo];
    }
}

- (void)_submitAccountInfo
{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSString *token = [NSString stringWithFormat:@"Bearer %@", [JYUser currentUser].token];
    [manager.requestSerializer setValue:token forHTTPHeaderField:@"Authorization"];

    NSString *url = [NSString stringWithFormat:@"%@%@", kUrlAPIBase, @"account/company"];

    [KVNProgress show];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

    __weak typeof(self) weakSelf = self;
    [manager POST:url
       parameters:[self _httpParameters]
          success:^(AFHTTPRequestOperation *operation, id responseObject) {
              NSLog(@"Account/individual Success responseObject: %@", responseObject);

              [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
              [KVNProgress showSuccessWithStatus:NSLocalizedString(@"Your Account Created!", nil)];

              [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationDidCreateAccount object:nil];
              [weakSelf.navigationController popToRootViewControllerAnimated:NO];
          }
          failure:^(AFHTTPRequestOperation *operation, NSError *error) {

              [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
              [KVNProgress dismiss];

              NSString *errorMessage = NSLocalizedString(@"Can't create the individual account due to network failure, please retry later", nil);
              [RKDropdownAlert title:NSLocalizedString(kErrorTitle, nil)
                             message:errorMessage
                     backgroundColor:FlatYellow
                           textColor:FlatBlack
                                time:5];
              
          }
     ];
}

@end
