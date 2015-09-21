//
//  JYProfileViewController.m
//  joyyios
//
//  Created by Ping Yang on 9/20/15.
//  Copyright © 2015 Joyy Inc. All rights reserved.
//

#import <AKPickerView/AKPickerView.h>
#import <TTTAttributedLabel/TTTAttributedLabel.h>

#import "JYButton.h"
#import "JYFloatLabeledTextField.h"
#import "JYProfileViewController.h"
#import "UITextField+Joyy.h"

@interface JYProfileViewController () <AKPickerViewDataSource, AKPickerViewDelegate, UIActionSheetDelegate, UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate>
@property (nonatomic) BOOL hasPhotoProvided;
@property (nonatomic) BOOL hasYobProvided;
@property (nonatomic) JYButton *submitButton;
@property (nonatomic) JYButton *avatarButton;
@property (nonatomic) JYButton *photoButton;
@property (nonatomic) TTTAttributedLabel *headerLabel;
@property (nonatomic) TTTAttributedLabel *genderLabel;
@property (nonatomic) AKPickerView *genderPickerView;
@property (nonatomic) NSUInteger gender;
@property (nonatomic) UITableView *tableView;
@property (nonatomic) UITextField *yobTextField;
@end

static NSString *const kProfileCellIdentifier = @"profileCell";
const CGFloat kHeaderLabelHeight = 50;
const CGFloat kAvatarButtonHeight = 200;
const CGFloat kAvatarButtonWidth = kAvatarButtonHeight;

@implementation JYProfileViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = NSLocalizedString(@"Profile", nil);

    self.gender = 0;
    self.hasPhotoProvided = NO;
    self.hasYobProvided = NO;

    [self.view addSubview:self.tableView];
    [self _showActionSheet];
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
        _tableView.backgroundColor = JoyyWhitePure;
        _tableView.showsHorizontalScrollIndicator = NO;
        _tableView.showsVerticalScrollIndicator = NO;
        _tableView.allowsSelection = NO;
        [_tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kProfileCellIdentifier];
    }
    return _tableView;
}

- (JYButton *)submitButton
{
    if (!_submitButton)
    {
        JYButton *button = [JYButton button];
        button.textLabel.text = NSLocalizedString(@"Save", nil);
        button.enabled = NO;
        [button addTarget:self action:@selector(_postProfile) forControlEvents:UIControlEventTouchUpInside];
        _submitButton = button;
    }
    return _submitButton;
}

- (JYButton *)avatarButton
{
    if (!_avatarButton)
    {
        CGRect frame = CGRectMake(0, 0, kAvatarButtonWidth, kAvatarButtonHeight);
        UIImage *image = image = [UIImage imageNamed:@"add"];
        JYButton *button = [JYButton iconButtonWithFrame:frame icon:image color:JoyyWhite];
        button.imageView.layer.borderWidth = 2;
        button.imageView.layer.borderColor = JoyyWhite.CGColor;
        button.imageView.layer.cornerRadius = 4;

        [button addTarget:self action:@selector(_didTapAvatarButton) forControlEvents:UIControlEventTouchUpInside];
        _avatarButton = button;
    }
    return _avatarButton;
}

- (JYButton *)photoButton
{
    if (!_photoButton)
    {
        CGRect frame = CGRectMake(0, 0, kAvatarButtonWidth, kAvatarButtonHeight);

        JYButton *button = [JYButton buttonWithFrame:frame buttonStyle:JYButtonStyleCentralImage shouldMaskImage:NO];
        button.imageView.contentMode = UIViewContentModeScaleAspectFill;
        button.imageView.layer.cornerRadius = 4;

        [button addTarget:self action:@selector(_didTapAvatarButton) forControlEvents:UIControlEventTouchUpInside];
        _photoButton = button;
    }
    return _photoButton;
}

- (TTTAttributedLabel *)headerLabel
{
    if (!_headerLabel)
    {
        CGFloat width = SCREEN_WIDTH - kMarginLeft - kMarginRight;
        CGRect frame = CGRectMake(kMarginLeft, 0, width, kHeaderLabelHeight);
        TTTAttributedLabel *label = [[TTTAttributedLabel alloc] initWithFrame:frame];
        label.numberOfLines = 0;
        label.lineBreakMode = NSLineBreakByWordWrapping;
        label.font = [UIFont systemFontOfSize:15];
        label.text = NSLocalizedString(@"Create your public profile", nil);
        label.textAlignment = NSTextAlignmentCenter;

        _headerLabel = label;
    }
    return _headerLabel;
}

- (TTTAttributedLabel *)genderLabel
{
    if (!_genderLabel)
    {
        CGRect frame = CGRectMake(kMarginLeft, 0, 100, kCellHeight);
        TTTAttributedLabel *label = [[TTTAttributedLabel alloc] initWithFrame:frame];
        label.font = [UIFont systemFontOfSize:16];
        label.textAlignment = NSTextAlignmentLeft;
        label.text = NSLocalizedString(@"Gender", nil);
        _genderLabel = label;
    }
    return _genderLabel;
}

- (AKPickerView *)genderPickerView
{
    if (!_genderPickerView)
    {
        CGRect frame = CGRectMake(0, 0, 100, kCellHeight);
        _genderPickerView = [[AKPickerView alloc] initWithFrame:frame];
        _genderPickerView.dataSource = self;
        _genderPickerView.delegate = self;
        [_genderPickerView reloadData];
    }
    return _genderPickerView;
}

- (UITextField *)yobTextField
{
    if (!_yobTextField)
    {
        CGFloat width = SCREEN_WIDTH - kMarginLeft - kMarginRight;
        CGRect frame = CGRectMake(0, 0, width, kCellHeight);

        JYFloatLabeledTextField *textField = [[JYFloatLabeledTextField alloc] initWithFrame:frame];
        textField.attributedPlaceholder =
        [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Year of Birth", nil) attributes:@{NSForegroundColorAttributeName : JoyyGray}];
        textField.delegate = self;
        textField.floatingLabel.font = [UIFont systemFontOfSize:11];
        textField.font = [UIFont systemFontOfSize:18];
        textField.keyboardType = UIKeyboardTypeNumberPad;
        textField.returnKeyType = UIReturnKeyDone;

        _yobTextField = textField;
    }
    return _yobTextField;
}

- (void)_refreshSubmitButton
{
    self.submitButton.enabled = (self.hasPhotoProvided && self.hasYobProvided);
}

- (void)_didTapAvatarButton
{
    [self _showActionSheet];
}

- (void)_showActionSheet
{
    NSString *title  = NSLocalizedString(@"Where to fetch your primary photo?", nil);
    NSString *cancel = NSLocalizedString(@"Cancel", nil);
    NSString *libary = NSLocalizedString(@"Photo Libary", nil);
    NSString *camera = NSLocalizedString(@"Camera", nil);


    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:title
                                                             delegate:self
                                                    cancelButtonTitle:cancel
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:libary, camera,nil];

    [actionSheet showInView:self.view];
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == actionSheet.cancelButtonIndex)
    {
        return;
    }

    if (buttonIndex == 0)
    {
        [self _presentCamera];
    }
    else
    {
        [self _presentPhotoLibary];
    }
}

- (void)_presentCamera
{
}

- (void)_presentPhotoLibary
{
}

#pragma mark -  AKPickerViewDataSource

- (NSUInteger)numberOfItemsInPickerView:(AKPickerView *)pickerView
{
    return 3;
}

- (NSString *)pickerView:(AKPickerView *)pickerView titleForItem:(NSInteger)item
{
    NSString *str = nil;
    switch (item)
    {
        case 0:
            str = NSLocalizedString(@"Male", nil);
            break;
        case 1:
            str = NSLocalizedString(@"Female", nil);
            break;
        default:
            str = NSLocalizedString(@"Other", nil);
            break;
    }
    return str;
}

#pragma mark - AKPickerViewDelegate

- (void)pickerView:(AKPickerView *)pickerView didSelectItem:(NSInteger)item
{
    self.gender = item;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 3;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kProfileCellIdentifier forIndexPath:indexPath];

    if ([cell.contentView subviews])
    {
        for (UIView *subview in [cell.contentView subviews])
        {
            [subview removeFromSuperview];
        }
    }

    cell.backgroundColor = JoyyWhitePure;
    if (indexPath.row == 0)
    {
        [cell.contentView addSubview:self.avatarButton];
        self.avatarButton.centerX = cell.centerX;
    }
    else if (indexPath.row == 1)
    {
        [cell.contentView addSubview:self.genderLabel];
        self.genderLabel.x = kMarginLeft;

        [cell.contentView addSubview:self.genderPickerView];
        self.genderPickerView.x = CGRectGetMaxX(self.genderLabel.frame) + 50;
    }
    else
    {
        [cell.contentView addSubview:self.yobTextField];
        self.yobTextField.x = kMarginLeft;
    }

    return cell;
}

- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    CGRect frame = CGRectMake(0, 0, SCREEN_WIDTH, kHeaderLabelHeight);
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

    [footer addSubview:self.submitButton];
    self.submitButton.y = kFooterHeight - self.submitButton.height;

    return footer;
}

#pragma mark - UITableView Delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0)
    {
        return kAvatarButtonHeight + 50;
    }
    return kCellHeight;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return kHeaderLabelHeight;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return kFooterHeight;
}

#pragma mark - UITextFieldDelegate methods

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    NSString *newStr = [textField.text stringByReplacingCharactersInRange:range withString:string];

    self.hasYobProvided = ([newStr length] <= 4);
    [self _refreshSubmitButton];

    return [newStr length] <= 4;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField
{
    self.hasYobProvided = NO;
    [self _refreshSubmitButton];

    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    [textField resignFirstResponder];
}

#pragma mark - Network

- (void)_postProfile
{
//    self.button.enabled = NO;
//
//    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
//    NSString *url = [NSString apiURLWithPath:@"credential/vcode"];
//
//    NSString *phoneNumber = nil;
//    NSString * language = [[[NSLocale preferredLanguages] objectAtIndex:0] substringToIndex:2];
//
//    NSDictionary *parameters = @{ @"phone": phoneNumber, @"language": language };
//
//    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
//
//    __weak typeof(self) weakSelf = self;
//    [manager GET:url
//      parameters:parameters
//         success:^(AFHTTPRequestOperation *operation, id responseObject) {
//             NSLog(@"Success: GET credential/vcode");
//             [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
//
//         }
//         failure:^(AFHTTPRequestOperation *operation, NSError *error) {
//             NSLog(@"Error: GET credential/vcode error: %@", error);
//
//             [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
//             weakSelf.button.enabled = YES;
//         }];
}

@end
