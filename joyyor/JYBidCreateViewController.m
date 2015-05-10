//
//  JYBidCreateViewController.m
//  joyyios
//
//  Created by Ping Yang on 4/19/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import <AFNetworking/AFNetworking.h>
#import <KVNProgress/KVNProgress.h>
#import <RKDropdownAlert/RKDropdownAlert.h>
#import <XLForm/XLFormViewController.h>
#import <XLForm/XLForm.h>

#import "JYButton.h"
#import "JYBidCreateViewController.h"
#import "JYOrderViewCell.h"
#import "JYPriceTextFieldCell.h"
#import "JYUser.h"

@interface JYBidCreateViewController ()

@property(nonatomic) UITableView *tableView;
@property(nonatomic) UILabel *priceLabel;
@property(nonatomic) UITextField *priceTextField;
@property(nonatomic) CGFloat tableViewHeight;
@property(nonatomic) UIScrollView *formView;
@property(nonatomic) XLFormViewController *formViewController;

@end

NSString *const kOrderBidCellIdentifier = @"orderBidCell";

@implementation JYBidCreateViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = NSLocalizedString(@"Bid", nil);
    self.view.backgroundColor = [UIColor whiteColor];

    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel", nil)
                                                                              style:UIBarButtonItemStyleBordered
                                                                             target:self
                                                                             action:@selector(_cancel)];

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Submit", nil)
                                                                              style:UIBarButtonItemStyleBordered
                                                                             target:self
                                                                             action:@selector(_submit)];

    self.tableViewHeight = [JYOrderViewCell cellHeightForText:[self.order valueForKey:@"note"]];
    [self _createTableView];
    [self _createForm];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)_cancel
{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)_createTableView
{
    self.tableView = [[UITableView alloc] initWithFrame:self.view.frame style:UITableViewStylePlain];
    CGFloat statusBarHeight = [UIApplication sharedApplication].statusBarFrame.size.height;
    CGFloat navBarHeight = self.navigationController.navigationBar.frame.size.height;
    self.tableView.height = self.tableViewHeight + statusBarHeight + navBarHeight;
    self.tableView.backgroundColor = FlatWhite;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.tableView registerClass:[JYOrderViewCell class] forCellReuseIdentifier:kOrderBidCellIdentifier];
    [self.view addSubview:self.tableView];
}

- (void)_createForm
{
    self.formView = [[UIScrollView alloc] initWithFrame:self.view.frame];
    self.formView.y = CGRectGetMaxY(self.tableView.frame);
    self.formView.height -= kButtonDefaultHeight;
    [self.view addSubview:self.formView];

    self.formViewController = [XLFormViewController new];
    self.formViewController.view = self.formView;

    XLFormDescriptor *form;
    XLFormSectionDescriptor *section;
    XLFormRowDescriptor *row;

    form = [XLFormDescriptor formDescriptorWithTitle:NSLocalizedString(@"Bid", nil)];
    form.assignFirstResponderOnShow = YES;

    // Price
    section = [XLFormSectionDescriptor formSectionWithTitle:NSLocalizedString(@"How much you like to charge?", nil)];
    [form addFormSection:section];
    row = [XLFormRowDescriptor formRowDescriptorWithTag:@"price" rowType:XLFormRowDescriptorTypePrice title:NSLocalizedString(@"", nil)];
    [row.cellConfig setObject:[UIFont boldSystemFontOfSize:23] forKey:@"textField.font"];
    [row.cellConfig setObject:FlatGreen forKey:@"textField.textColor"];
    [row.cellConfig setObject:@(NSTextAlignmentCenter) forKey:@"textField.textAlignment"];
    row.value = @"$";
    [section addFormRow:row];

    // Expire Time
    row = [XLFormRowDescriptor formRowDescriptorWithTag:@"expire_at" rowType:XLFormRowDescriptorTypeDateTime title:NSLocalizedString(@"When your offer will expire?", nil)];
    [row.cellConfigAtConfigure setObject:[NSDate date] forKey:@"minimumDate"];
    [row.cellConfigAtConfigure setObject:@(5) forKey:@"minuteInterval"];
    row.value = [NSDate dateWithTimeIntervalSinceNow:k15Minutes];
    [section addFormRow:row];

    self.formViewController.form = form;
    [self.formViewController viewDidLoad];
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
    JYOrderViewCell *cell =
    (JYOrderViewCell *)[tableView dequeueReusableCellWithIdentifier:kOrderBidCellIdentifier forIndexPath:indexPath];

    [cell presentOrder:self.order];

    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return self.tableViewHeight;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Network

- (NSDictionary *)_httpParameters
{
    NSMutableDictionary *parameters = [NSMutableDictionary new];

    // price
    NSString *priceString = [[self.formViewController.formValues valueForKey:@"price"] substringFromIndex:1];
    NSUInteger price = priceString? [priceString  unsignedIntegerValue]: 0;
    [parameters setObject:@(price) forKey:@"price"];

    // expire time
    NSDate *expire = (NSDate *)[self.formViewController.formValues objectForKey:@"expire_at"];
    NSUInteger expireTime = (NSUInteger)expire.timeIntervalSinceReferenceDate;
    [parameters setObject:@(expireTime) forKey:@"expire_at"];

    // order_id
    NSUInteger orderId = [[self.order valueForKey:@"id"] unsignedIntegerValue];
    [parameters setObject:@(orderId) forKey:@"order_id"];

    // note
    [parameters setObject:@":)" forKey:@"note"];

    return parameters;
}


- (void)_submit
{
    NSDictionary *parameters = [self _httpParameters];
    NSLog(@"parameters = %@", parameters);

    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSString *token = [NSString stringWithFormat:@"Bearer %@", [JYUser currentUser].token];
    [manager.requestSerializer setValue:token forHTTPHeaderField:@"Authorization"];

    NSString *url = [NSString stringWithFormat:@"%@%@", kUrlAPIBase, @"bids"];

    [KVNProgress show];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

    __weak typeof(self) weakSelf = self;
    [manager POST:url
       parameters:parameters
          success:^(AFHTTPRequestOperation *operation, id responseObject) {
              NSLog(@"Bid Success responseObject: %@", responseObject);

              [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
              [KVNProgress showSuccessWithStatus:NSLocalizedString(@"The Bid Created!", nil)];
              [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationDidCreateBid object:nil];
              [weakSelf _cancel];
          }
          failure:^(AFHTTPRequestOperation *operation, NSError *error) {

              NSLog(@"Bid fail error: %@", error);

              [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
              [KVNProgress dismiss];

              NSString *errorMessage = NSLocalizedString(@"The bid cannot be created due to network failure, please retry later", nil);
              [RKDropdownAlert title:NSLocalizedString(@"Something wrong ...", nil)
                             message:errorMessage
                     backgroundColor:FlatYellow
                           textColor:FlatBlack
                                time:5];
              
          }
     ];
}

@end
