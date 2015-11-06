//
//  JYVerificationViewController.m
//  joyyios
//
//  Created by Ping Yang on 9/14/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

#import <KVNProgress/KVNProgress.h>
#import <RKDropdownAlert/RKDropdownAlert.h>
#import <TTTAttributedLabel/TTTAttributedLabel.h>

#import "JYButton.h"
#import "JYSignInViewController.h"
#import "JYSignUpViewController.h"
#import "JYVerificationViewController.h"

@interface JYVerificationViewController () <UIActionSheetDelegate, UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate>
@property (nonatomic) JYButton *button;
@property (nonatomic) TTTAttributedLabel *headerLabel;
@property (nonatomic) UITableView *tableView;
@property (nonatomic) UITextField *textField;
@property (nonatomic) NSArray *usernameList;
@end

static NSString *const kVerificationCellIdentifier = @"verificationCell";

@implementation JYVerificationViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = NSLocalizedString(@"Verify", nil);
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Next", nil) style:UIBarButtonItemStylePlain target:self action:@selector(_didTapButton)];
    [self _enableButtons:NO];

    [self.view addSubview:self.tableView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)dealloc
{
}

- (UITableView *)tableView
{
    if (!_tableView)
    {
        _tableView = [[UITableView alloc] initWithFrame:self.view.frame style:UITableViewStylePlain];
        _tableView.dataSource = self;
        _tableView.delegate = self;
        _tableView.backgroundColor = JoyyWhiter;
        _tableView.allowsSelection = NO;
        _tableView.showsHorizontalScrollIndicator = NO;
        _tableView.showsVerticalScrollIndicator = NO;
        [_tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kVerificationCellIdentifier];
    }
    return _tableView;
}

- (JYButton *)button
{
    if (!_button)
    {
        _button = [JYButton button];
        _button.textLabel.text = NSLocalizedString(@"Next", nil);
        [_button addTarget:self action:@selector(_didTapButton) forControlEvents:UIControlEventTouchUpInside];
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
        label.text = NSLocalizedString(@"Please input the verification code you received.", nil);
        label.textAlignment = NSTextAlignmentCenter;

        _headerLabel = label;
    }
    return _headerLabel;
}

- (UITextField *)textField
{
    if (!_textField)
    {
        CGRect frame = CGRectMake(0, 0, 100, kCellHeight);

        UITextField *textField = [[UITextField alloc] initWithFrame:frame];
        textField.delegate = self;
        textField.backgroundColor = JoyyWhitePure;
        textField.tintColor = JoyyBlue;
        textField.font = [UIFont systemFontOfSize:38];
        textField.textAlignment = NSTextAlignmentLeft;
        textField.keyboardType = UIKeyboardTypeNumberPad;

        _textField = textField;
    }
    return _textField;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kVerificationCellIdentifier forIndexPath:indexPath];
    cell.backgroundColor = JoyyWhiter;

    if ([cell.contentView subviews])
    {
        for (UIView *subview in [cell.contentView subviews])
        {
            [subview removeFromSuperview];
        }
    }

    if (indexPath.row == 0)
    {
        [cell.contentView addSubview:self.textField];
        self.textField.x = (SCREEN_WIDTH - self.textField.width) / 2;
        [self.textField becomeFirstResponder];
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

#pragma mark - UITextFieldDelegate methods

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    NSString *newStr = [textField.text stringByReplacingCharactersInRange:range withString:string];

    BOOL more = (([newStr length] <= 4) && [newStr onlyContainsDigits]);

    [self _enableButtons:(newStr.length >= 4)];
    return more;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField
{
    [self _enableButtons:NO];
    return YES;
}

#pragma mark - Handlers

- (void)_receivedUsenames:(NSArray *)usernameList
{
    self.usernameList = usernameList;
    if ([usernameList count] == 0)
    {
        [self _showSignupView];
    }
    else
    {
        [self _showUsernames];
    }
}

- (void)_showUsernames
{
    NSString *title = nil;
    NSString *cancel = nil;

    if (self.usernameList.count == 1)
    {
        title  = NSLocalizedString(@"Hi, is this you?", nil);
        cancel = NSLocalizedString(@"No", nil);
    }
    else
    {
        title  = NSLocalizedString(@"Hi, which one is you?", nil);
        cancel = NSLocalizedString(@"None of them", nil);
    }

    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:title
                                                             delegate:self
                                                    cancelButtonTitle:nil
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:nil];

    for (NSDictionary *dict in self.usernameList)
    {
        NSString *username = [dict objectForKey:@"username"];
        [actionSheet addButtonWithTitle:username];
    }

    actionSheet.cancelButtonIndex = [actionSheet addButtonWithTitle:cancel];

    [actionSheet showInView:self.view];
}

- (void)_showSignupView
{
    JYSignUpViewController *vc = [JYSignUpViewController new];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)_showSigninViewWithUsername:(NSString *)username
{
    JYSignInViewController *vc = [JYSignInViewController new];
    vc.username = username;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)_enableButtons:(BOOL)enabled
{
    self.button.enabled = enabled;
    self.navigationItem.rightBarButtonItem.enabled = enabled;
}

#pragma mark - UIActionSheetDelegate methods

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == actionSheet.cancelButtonIndex)
    {
        [JYCredential current].phoneNumber = self.phoneNumber;
        [self _showSignupView];
        return;
    }

    if (buttonIndex < self.usernameList.count )
    {
        NSString *username = self.usernameList[buttonIndex];
        [self _showSigninViewWithUsername:username];
    }
}

#pragma mark - Network

- (void)_didTapButton
{
    [self _enableButtons:NO];
    [self _fetchUserName];
}

- (void)_fetchUserName
{
    [self.textField resignFirstResponder];

    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSString *url = [NSString apiURLWithPath:@"code/validate"];

    NSString *code = [self.textField.text substringToIndex:4];
    NSDictionary *parameters = @{ @"phone": self.phoneNumber, @"code": code };

    [KVNProgress show];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

    __weak typeof(self) weakSelf = self;
    [manager POST:url
      parameters:parameters
         success:^(AFHTTPRequestOperation *operation, id responseObject) {
             NSLog(@"Success: POST code/validate. responseObject = %@", responseObject);
             [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
             [KVNProgress dismiss];

             NSArray *usernameList = (NSArray *)responseObject;
             [weakSelf _receivedUsenames:usernameList];
         }
         failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             NSLog(@"Error: POST code/validate error: %@", error);
             [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
             [KVNProgress dismiss];

             [weakSelf _enableButtons:YES];

             NSString *errorMessage = [error.userInfo valueForKey:NSLocalizedDescriptionKey];

             [RKDropdownAlert title:NSLocalizedString(kErrorTitle, nil)
                            message:errorMessage
                    backgroundColor:FlatYellow
                          textColor:FlatBlack
                               time:5];
         }];
}

@end