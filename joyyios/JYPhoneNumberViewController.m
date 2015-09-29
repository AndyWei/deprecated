//
//  JYSignViewController.m
//  joyyios
//
//  Created by Ping Yang on 3/30/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

#import <CoreTelephony/CTCarrier.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <TTTAttributedLabel/TTTAttributedLabel.h>
#import <VMaskTextField/VMaskTextField.h>

#import "JYButton.h"
#import "JYCountryListViewController.h"
#import "JYPhoneNumberViewController.h"
#import "JYVerificationViewController.h"
#import "UITextField+Joyy.h"

@interface JYPhoneNumberViewController () <UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate>
@property (nonatomic) JYButton *button;
@property (nonatomic) NSString *countryCode;
@property (nonatomic) TTTAttributedLabel *headerLabel;
@property (nonatomic) TTTAttributedLabel *countryNameLabel;
@property (nonatomic) TTTAttributedLabel *countryNumberLabel;
@property (nonatomic) UITableView *tableView;
@property (nonatomic) VMaskTextField *phoneNumberTextField;
@end

static NSString *const kPhoneNumberCellIdentifier = @"phoneNumberCell";
CGFloat const kCountryNumberWidth = 60;

@implementation JYPhoneNumberViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Verify", nil) style:UIBarButtonItemStylePlain target:self action:@selector(_didTapVerifyButton)];

    [self _enableButtons:NO];

    self.title = NSLocalizedString(@"Your Phone Number", nil);
    [self.view addSubview:self.tableView];

    CTTelephonyNetworkInfo *netInfo = [[CTTelephonyNetworkInfo alloc] init];
    CTCarrier *carrier = [netInfo subscriberCellularProvider];
    self.countryCode = [carrier.isoCountryCode uppercaseString];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_countryCodeUpdated:) name:kNotificationDidChangeCountryCode object:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)_countryCodeUpdated:(NSNotification *)notification
{
    NSDictionary *info = [notification userInfo];
    if (info)
    {
        id value = [info objectForKey:@"country_code"];
        if (value != [NSNull null])
        {
            NSString *countryCode = (NSString *)value;
            self.countryCode = countryCode;
        }
    }

    [self.navigationController popViewControllerAnimated:YES];
}

- (UITableView *)tableView
{
    if (!_tableView)
    {
        _tableView = [[UITableView alloc] initWithFrame:self.view.frame style:UITableViewStylePlain];
        _tableView.dataSource = self;
        _tableView.delegate = self;
        _tableView.backgroundColor = JoyyWhiter;
        _tableView.showsHorizontalScrollIndicator = NO;
        _tableView.showsVerticalScrollIndicator = NO;
        [_tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kPhoneNumberCellIdentifier];
    }
    return _tableView;
}

- (JYButton *)button
{
    if (!_button)
    {
        _button = [JYButton button];
        _button.textLabel.text = NSLocalizedString(@"Verify", nil);
        [_button addTarget:self action:@selector(_didTapVerifyButton) forControlEvents:UIControlEventTouchUpInside];
    }
    return _button;
}

- (TTTAttributedLabel *)headerLabel
{
    if (!_headerLabel)
    {
        CGFloat width = SCREEN_WIDTH - kMarginLeft - kMarginRight;
        CGRect frame = CGRectMake(kMarginLeft, 0, width, kHeaderHeight);
        TTTAttributedLabel *label = [[TTTAttributedLabel alloc] initWithFrame:frame];
        label.numberOfLines = 0;
        label.lineBreakMode = NSLineBreakByWordWrapping;
        label.font = [UIFont systemFontOfSize:15];
        label.text = NSLocalizedString(@"Please confirm your country code and enter your phone number", nil);
        label.textAlignment = NSTextAlignmentCenter;

        _headerLabel = label;
    }
    return _headerLabel;
}

- (TTTAttributedLabel *)countryNameLabel
{
    if (!_countryNameLabel)
    {
        CGRect frame = CGRectMake(0, 0, SCREEN_WIDTH, kCellHeight);
        TTTAttributedLabel *label = [[TTTAttributedLabel alloc] initWithFrame:frame];
        label.font = [UIFont systemFontOfSize:16];
        label.textAlignment = NSTextAlignmentLeft;
        label.textColor = JoyyBlue;
        _countryNameLabel = label;
    }
    return _countryNameLabel;
}

- (TTTAttributedLabel *)countryNumberLabel
{
    if (!_countryNumberLabel)
    {
        CGRect frame = CGRectMake(0, 0, kCountryNumberWidth, kCellHeight);
        TTTAttributedLabel *label = [[TTTAttributedLabel alloc] initWithFrame:frame];
        label.font = [UIFont systemFontOfSize:20];
        label.textAlignment = NSTextAlignmentCenter;

        _countryNumberLabel = label;
    }
    return _countryNumberLabel;
}

- (VMaskTextField *)phoneNumberTextField
{
    if (!_phoneNumberTextField)
    {
        CGFloat width = SCREEN_WIDTH - CGRectGetWidth(self.countryNumberLabel.frame);
        CGRect frame = CGRectMake(0, 0, width, kCellHeight);

        VMaskTextField *textField = [[VMaskTextField alloc] initWithFrame:frame];
        textField.delegate = self;
        textField.font = [UIFont systemFontOfSize:20];
        textField.textAlignment = NSTextAlignmentLeft;
        textField.keyboardType = UIKeyboardTypeNumberPad;
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
        textField.placeholder = NSLocalizedString(@"your phone number", nil);

        _phoneNumberTextField = textField;
    }
    return _phoneNumberTextField;
}

- (void)setCountryCode:(NSString *)countryCode
{
    _countryCode = countryCode;

    NSString *localizedCountryName = [[NSLocale currentLocale] displayNameForKey:NSLocaleCountryCode value:_countryCode];
    self.countryNameLabel.text = localizedCountryName;

    NSString *dialingCode = [NSString dialingCodeForCountryCode:_countryCode];
    self.countryNumberLabel.text = [NSString stringWithFormat:@"+%@", dialingCode];

    // For NANP countries, use US format
    if ([self.countryNumberLabel.text isEqualToString:@"+1"])       // NANP
    {
        self.phoneNumberTextField.mask = @"(###) ###-####";
    }
    else if ([self.countryNumberLabel.text isEqualToString:@"+86"]) // China
    {
        self.phoneNumberTextField.mask = @"###-####-####";
    }
    else
    {
        self.phoneNumberTextField.mask = @"##############";         // Others
    }
}

- (NSString *)_userPhoneNumberDigits
{
    NSString *dialingCode = [NSString dialingCodeForCountryCode:self.countryCode];
    NSString *localPhoneNumber = [self.phoneNumberTextField.text pureNumberString];
    return [NSString stringWithFormat:@"%@%@", dialingCode, localPhoneNumber];
}

- (void)_showNextScreenWithPhoneNumber:(NSString *)phoneNumber
{
    JYVerificationViewController *vc = [JYVerificationViewController new];
    vc.phoneNumber = phoneNumber;
    [self.navigationController pushViewController:vc animated:YES];

    [self _enableButtons:YES];
}

- (void)_enableButtons:(BOOL)enabled
{
    self.button.enabled = enabled;
    self.navigationItem.rightBarButtonItem.enabled = enabled;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kPhoneNumberCellIdentifier forIndexPath:indexPath];

    if ([cell.contentView subviews])
    {
        for (UIView *subview in [cell.contentView subviews])
        {
            [subview removeFromSuperview];
        }
    }

    if (indexPath.row == 0)
    {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

        [cell.contentView addSubview:self.countryNameLabel];
        self.countryNameLabel.x = 20;
    }
    else
    {
        cell.accessoryType = UITableViewCellAccessoryNone;

        [cell.contentView addSubview:self.countryNumberLabel];
        [cell.contentView addSubview:self.phoneNumberTextField];

        self.phoneNumberTextField.x = CGRectGetMaxX(self.countryNumberLabel.frame);
        [self.phoneNumberTextField becomeFirstResponder];
    }

    return cell;
}

- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    CGRect frame = CGRectMake(0, 0, SCREEN_WIDTH, kHeaderHeight);
    UIView *header = [[UIView alloc] initWithFrame:frame];
    header.backgroundColor = ClearColor;
    [header addSubview:self.headerLabel];

    return header;
}

- (UIView*)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    CGRect frame = CGRectMake(0, 0, SCREEN_WIDTH, kFooterHeight);
    UIView *footer = [[UIView alloc] initWithFrame:frame];
    footer.backgroundColor = ClearColor;

    [footer addSubview:self.button];
    self.button.y = kFooterHeight - self.button.height;

    return footer;
}

#pragma mark - UITableView Delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return kCellHeight;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return kHeaderHeight;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return kFooterHeight;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];

    if (indexPath.row == 0)
    {
        JYCountryListViewController *vc = [JYCountryListViewController new];
        vc.currentCountryName = self.countryNameLabel.text;
        [self.navigationController pushViewController:vc animated:YES];
    }
}

#pragma mark - UITextFieldDelegate methods

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    NSString *newStr = [textField.text stringByReplacingCharactersInRange:range withString:string];

    if ([self.countryNumberLabel.text isEqualToString:@"+1"])
    {
        [self _enableButtons:(newStr.length >= 14)];
    }
    else
    {
        [self _enableButtons:(newStr.length > 3)];
    }

    return  [self.phoneNumberTextField shouldChangeCharactersInRange:range replacementString:string];
}

- (BOOL)textFieldShouldClear:(UITextField *)textField
{
    [self _enableButtons:NO];
    return YES;
}

#pragma mark - Network

- (void)_didTapVerifyButton
{
    [self _enableButtons:NO];
    [self _fetchVerificationCode];
}

- (void)_fetchVerificationCode
{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSString *url = [NSString apiURLWithPath:@"credential/vcode"];

    NSString *phoneNumber = [self _userPhoneNumberDigits];
    NSString * language = [[[NSLocale preferredLanguages] objectAtIndex:0] substringToIndex:2];

    NSDictionary *parameters = @{ @"phone": phoneNumber, @"language": language };

    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

    __weak typeof(self) weakSelf = self;
    [manager GET:url
      parameters:parameters
         success:^(AFHTTPRequestOperation *operation, id responseObject) {
             NSLog(@"Success: GET credential/vcode");
             [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
             
         }
         failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             NSLog(@"Error: GET credential/vcode error: %@", error);

             [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
             [weakSelf _enableButtons:YES];
         }];

    [self _showNextScreenWithPhoneNumber:phoneNumber];
}

@end