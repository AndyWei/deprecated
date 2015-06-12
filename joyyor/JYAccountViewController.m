//
//  JYAccountViewController.m
//  joyyor
//
//  Created by Ping Yang on 6/11/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import <XLForm/XLForm.h>

#import "AppDelegate.h"
#import "JYAccountBaseViewController.h"
#import "JYAccountCompanyViewController.h"
#import "JYAccountIndividualViewController.h"
#import "JYAccountViewController.h"

@import MapKit;


@interface JYAccountViewController ()

@end


@implementation JYAccountViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = NSLocalizedString(@"Account Type", nil);

    UIBarButtonItem *barButton =
    [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Next", nil) style:UIBarButtonItemStylePlain target:self action:@selector(_fetchCurrentAddress)];
    self.navigationItem.rightBarButtonItem = barButton;

    [self _createForm];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)_createForm
{
    XLFormDescriptor *form = [XLFormDescriptor formDescriptor];
    form.assignFirstResponderOnShow = YES;

    XLFormSectionDescriptor *section = [XLFormSectionDescriptor formSection];
    [form addFormSection:section];

    XLFormRowDescriptor *row = [XLFormRowDescriptor formRowDescriptorWithTag:@"account_type" rowType:XLFormRowDescriptorTypeSelectorActionSheet title:NSLocalizedString(@"Choose Your Account Type", nil)];
    row.selectorOptions = @[[XLFormOptionsObject formOptionsObjectWithValue:@(0) displayText:@"Individual"],
                            [XLFormOptionsObject formOptionsObjectWithValue:@(1) displayText:@"Company"]
                            ];
    row.value = [XLFormOptionsObject formOptionsObjectWithValue:@(0) displayText:@"Individual"];
    [section addFormRow:row];
    self.form = form;
}

- (void)_presentCreateAccountViewWithAddress:(NSDictionary *)address
{
    XLFormOptionsObject *accountType = [self.formValues valueForKey:@"account_type"];
    BOOL isCompany = [accountType.formValue integerValue] == 1;

    JYAccountBaseViewController *vc = isCompany ? [JYAccountCompanyViewController new] : [JYAccountIndividualViewController new];
    vc.currentAddress = address;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)_fetchCurrentAddress
{
    self.navigationItem.rightBarButtonItem.enabled = NO;

    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    CLLocation *location = [[CLLocation alloc] initWithLatitude:appDelegate.currentCoordinate.latitude longitude:appDelegate.currentCoordinate.longitude];
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    __weak typeof(self) weakSelf = self;
    [geocoder reverseGeocodeLocation:location
                   completionHandler:^(NSArray *placemarks, NSError *error) {
                       NSDictionary *address = nil;
                       if (error)
                       {
                           NSLog(@"Geocode failed with error %@", error);
                       }
                       else
                       {
                           CLPlacemark *placemark = [placemarks objectAtIndex:0];
                           address = placemark.addressDictionary;
                       }

                       weakSelf.navigationItem.rightBarButtonItem.enabled = YES;
                       [weakSelf _presentCreateAccountViewWithAddress:address];
                   }];
}

@end
