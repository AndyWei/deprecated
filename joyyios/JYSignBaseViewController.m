//
//  JYSignBaseViewController.m
//  joyyios
//
//  Created by Ping Yang on 3/26/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

#import <KVNProgress/KVNProgress.h>
#import <RKDropdownAlert/RKDropdownAlert.h>
#import <TTTAttributedLabel/TTTAttributedLabel.h>

#import "JYButton.h"
#import "JYSignBaseViewController.h"

@interface JYSignBaseViewController () <UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate>
@property (nonatomic) TTTAttributedLabel *headerLabel;
@property (nonatomic) TTTAttributedLabel *usernameLabel;
@property (nonatomic) TTTAttributedLabel *passwordLabel;
@property (nonatomic) UITableView *tableView;
@end

static NSString *const kSignCellIdentifier = @"signCell";
CGFloat const kSignLabelWidth = 150;

@implementation JYSignBaseViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.view addSubview:self.tableView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
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
        [_tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kSignCellIdentifier];
    }
    return _tableView;
}

- (JYButton *)signButton
{
    if (!_signButton)
    {
        JYButton *button = [JYButton button];
        button.enabled = NO;

        _signButton = button;
    }
    return _signButton;
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
        label.text = NSLocalizedString(@"People can see your username, so please choose a good one.", nil);
        label.textAlignment = NSTextAlignmentCenter;

        _headerLabel = label;
    }
    return _headerLabel;
}

- (TTTAttributedLabel *)usernameLabel
{
    if (!_usernameLabel)
    {
        _usernameLabel = [self _createLabel];
        _usernameLabel.text = NSLocalizedString(@"Username", nil);
    }
    return _usernameLabel;
}

- (TTTAttributedLabel *)passwordLabel
{
    if (!_passwordLabel)
    {
        _passwordLabel = [self _createLabel];
        _passwordLabel.text = NSLocalizedString(@"Password", nil);
    }
    return _passwordLabel;
}

- (UITextField *)usernameField
{
    if (!_usernameField)
    {
        _usernameField = [self _createTextField];
        _usernameField.placeholder = NSLocalizedString(@"at least 4 characters", nil);
    }
    return _usernameField;
}

- (UITextField *)passwordField
{
    if (!_passwordField)
    {
        _passwordField = [self _createTextField];
        _passwordField.placeholder = NSLocalizedString(@"at least 4 characters", nil);
        _passwordField.secureTextEntry = YES;
    }
    return _passwordField;
}

- (TTTAttributedLabel *)_createLabel
{
    CGRect frame = CGRectMake(0, 0, kSignLabelWidth, kCellHeight);
    TTTAttributedLabel *label = [[TTTAttributedLabel alloc] initWithFrame:frame];
    label.font = [UIFont systemFontOfSize:20];
    label.textAlignment = NSTextAlignmentRight;

    return label;
}

- (UITextField *)_createTextField
{
    CGRect frame = CGRectMake(0, 0, 0, kCellHeight);
    UITextField *textField = [[UITextField alloc] initWithFrame:frame];
    textField.delegate = self;
    textField.backgroundColor = JoyyWhitePure;
    textField.font = [UIFont systemFontOfSize:20];
    textField.textAlignment = NSTextAlignmentLeft;
    textField.layer.borderWidth = 2.0f;

    return textField;
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
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kSignCellIdentifier forIndexPath:indexPath];
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
        [cell.contentView addSubview:self.usernameLabel];
        [cell.contentView addSubview:self.usernameField];
        self.usernameLabel.x = kMarginLeft;
        self.usernameField.x = CGRectGetMidX(self.usernameLabel.frame) + kMarginLeft;
        self.usernameField.width = SCREEN_WIDTH - self.usernameField.x - kMarginRight;
    }
    else
    {
        [cell.contentView addSubview:self.passwordLabel];
        [cell.contentView addSubview:self.passwordField];
        self.passwordLabel.x = kMarginLeft;
        self.passwordField.x = CGRectGetMidX(self.passwordLabel.frame) + kMarginLeft;
        self.passwordField.width = SCREEN_WIDTH - self.passwordField.x - kMarginRight;
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

    [footer addSubview:self.signButton];
    self.signButton.y = kFooterHeight - self.signButton.height;

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

    if (textField == self.usernameField)
    {
        self.signButton.enabled = self.passwordField.text.length >= 4 && (newStr.length >= 4);
    }
    else
    {
        self.signButton.enabled = self.usernameField.text.length >= 4 && (newStr.length >= 4);

        if (newStr.length >= 4)
        {
            self.passwordField.layer.borderColor = [FlatGreen CGColor];
        }
        else
        {
            self.passwordField.layer.borderColor = [FlatRed CGColor];
        }
    }

    return YES;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField
{
    self.signButton.enabled = NO;
    textField.layer.borderColor = [FlatRed CGColor];

    return YES;
}

@end
