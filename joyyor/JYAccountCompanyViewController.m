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
    XLFormDescriptor *form;
    XLFormSectionDescriptor *section;
    XLFormRowDescriptor *row;

    form = [XLFormDescriptor formDescriptor];
    form.assignFirstResponderOnShow = YES;

    // Personal Info
    section = [XLFormSectionDescriptor formSectionWithTitle:NSLocalizedString(@"Company Information", nil)];
    [form addFormSection:section];
    row = [XLFormRowDescriptor formRowDescriptorWithTag:@"businessName" rowType:XLFormRowDescriptorTypeFloatLabeledName title:NSLocalizedString(@"Business Name", nil)];
    row.required = YES;
    [section addFormRow:row];

    row = [XLFormRowDescriptor formRowDescriptorWithTag:@"businessTaxId" rowType:XLFormRowDescriptorTypeFloatLabeledInteger title:NSLocalizedString(@"EIN (Employer Identification Number)", nil)];
    row.required = YES;
    [section addFormRow:row];

    // Company Address
    section = [XLFormSectionDescriptor formSectionWithTitle:NSLocalizedString(@"Company Address", nil)];
    [form addFormSection:section];
    row = [XLFormRowDescriptor formRowDescriptorWithTag:@"businessLine1" rowType:XLFormRowDescriptorTypeFloatLabeledText title:NSLocalizedString(@"Address line 1", nil)];
    row.required = YES;
    [section addFormRow:row];

    row = [XLFormRowDescriptor formRowDescriptorWithTag:@"businessLine2" rowType:XLFormRowDescriptorTypeFloatLabeledText title:NSLocalizedString(@"Address line 2 (optional)", nil)];
    [section addFormRow:row];

    row = [XLFormRowDescriptor formRowDescriptorWithTag:@"businessCity" rowType:XLFormRowDescriptorTypeFloatLabeledName title:NSLocalizedString(@"City", nil)];
    row.required = YES;
    row.value = [NSDate dateWithTimeIntervalSince1970:0];
    [section addFormRow:row];

    row = [XLFormRowDescriptor formRowDescriptorWithTag:@"businessState" rowType:XLFormRowDescriptorTypeFloatLabeledName title:NSLocalizedString(@"State", nil)];
    row.required = YES;
    [section addFormRow:row];

    row = [XLFormRowDescriptor formRowDescriptorWithTag:@"businessZipcode" rowType:XLFormRowDescriptorTypeFloatLabeledZipcode title:NSLocalizedString(@"Zip Code", nil)];
    row.required = YES;
    [section addFormRow:row];

    // Representative Personal Information
    section = [XLFormSectionDescriptor formSectionWithTitle:NSLocalizedString(@"Company Representative Personal Information", nil)];
    [form addFormSection:section];
    row = [XLFormRowDescriptor formRowDescriptorWithTag:@"firstName" rowType:XLFormRowDescriptorTypeFloatLabeledName title:NSLocalizedString(@"First Name", nil)];
    row.required = YES;
    [section addFormRow:row];

    row = [XLFormRowDescriptor formRowDescriptorWithTag:@"lastName" rowType:XLFormRowDescriptorTypeFloatLabeledName title:NSLocalizedString(@"Last Name", nil)];
    row.required = YES;
    [section addFormRow:row];

    row = [XLFormRowDescriptor formRowDescriptorWithTag:@"dob" rowType:XLFormRowDescriptorTypeDate title:NSLocalizedString(@"Date of Birth", nil)];
    NSString* str = @"01/01/1980";
    NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"MM/dd/yyyy"];
    row.value = [formatter dateFromString:str];
    [section addFormRow:row];

    row = [XLFormRowDescriptor formRowDescriptorWithTag:@"personalId" rowType:XLFormRowDescriptorTypeFloatLabeledSSN title:NSLocalizedString(@"Social Security Number", nil)];
    row.required = YES;
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

    row = [XLFormRowDescriptor formRowDescriptorWithTag:@"zipcode" rowType:XLFormRowDescriptorTypeFloatLabeledZipcode title:NSLocalizedString(@"Zip Code", nil)];
    row.required = YES;
    [section addFormRow:row];

    // Bank Account
    section = [XLFormSectionDescriptor formSectionWithTitle:NSLocalizedString(@"Company Bank Information", nil)];
    [form addFormSection:section];
    row = [XLFormRowDescriptor formRowDescriptorWithTag:@"routingNumber" rowType:XLFormRowDescriptorTypeFloatLabeledInteger title:NSLocalizedString(@"Routing Number", nil)];
    row.required = YES;
    [section addFormRow:row];

    row = [XLFormRowDescriptor formRowDescriptorWithTag:@"accountNumber" rowType:XLFormRowDescriptorTypeFloatLabeledInteger title:NSLocalizedString(@"Account Number", nil)];
    row.required = YES;
    [section addFormRow:row];

    self.form = form;
}

- (NSDictionary *)_httpParameters
{
    NSMutableDictionary *parameters = [NSMutableDictionary new];

    // Company information
    [parameters setValue:[self.formValues valueForKey:@"businessName"] forKey:@"businessName"];
    [parameters setValue:[self.formValues valueForKey:@"businessTaxId"] forKey:@"businessTaxId"];

    // Company address
    [parameters setValue:[self.formValues valueForKey:@"businessLine1"] forKey:@"businessLine1"];
    [parameters setValue:[self.formValues valueForKey:@"businessCity"] forKey:@"businessCity"];
    [parameters setValue:[self.formValues valueForKey:@"businessState"] forKey:@"businessState"];
    [parameters setValue:[self.formValues valueForKey:@"businessZipcode"] forKey:@"businessZipcode"];
    if ([self.formValues objectForKey:@"businessLine2"])
    {
        [parameters setValue:[self.formValues valueForKey:@"businessLine2"] forKey:@"businessLine2"];
    }

    // Representative information
    [parameters setValue:[self.formValues valueForKey:@"firstName"] forKey:@"firstName"];
    [parameters setValue:[self.formValues valueForKey:@"lastName"] forKey:@"lastName"];
    [parameters setValue:[self.formValues valueForKey:@"personalId"] forKey:@"personalId"];

    // Representative address
    [parameters setValue:[self.formValues valueForKey:@"line1"] forKey:@"line1"];
    [parameters setValue:[self.formValues valueForKey:@"city"] forKey:@"city"];
    [parameters setValue:[self.formValues valueForKey:@"state"] forKey:@"state"];
    [parameters setValue:[self.formValues valueForKey:@"zipcode"] forKey:@"zipcode"];
    if ([self.formValues objectForKey:@"line2"])
    {
        [parameters setValue:[self.formValues valueForKey:@"line2"] forKey:@"line2"];
    }

    // Bank account
    [parameters setValue:[self.formValues valueForKey:@"routingNumber"] forKey:@"routingNumber"];
    [parameters setValue:[self.formValues valueForKey:@"accountNumber"] forKey:@"accountNumber"];

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
