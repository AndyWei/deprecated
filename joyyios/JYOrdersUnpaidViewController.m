//
//  JYOrdersUnpaidViewController.m
//  joyyios
//
//  Created by Ping Yang on 4/25/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import <AFNetworking/AFNetworking.h>
#import <KVNProgress/KVNProgress.h>
#import <Stripe/Stripe.h>

#import "JYOrdersUnpaidViewController.h"
#import "JYBidViewCell.h"
#import "JYCreditCard.h"
#import "JYOrderCard.h"
#import "JYUser.h"
#import "UICustomActionSheet.h"

@interface JYOrdersUnpaidViewController ()

@property(nonatomic) NSIndexPath *selectedIndexPath;
@property(nonatomic) NSString *stripeToken;
@property(nonatomic) NSMutableArray *creditCardList;

@end


static NSString *const kBidCellIdentifier = @"bidCell";

@implementation JYOrdersUnpaidViewController

+ (UILabel *)sharedAcceptLabel
{
    static UILabel *_sharedAcceptLabel = nil;
    static dispatch_once_t done;

    dispatch_once(&done, ^{
        _sharedAcceptLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 60, 30)];
        _sharedAcceptLabel.font = [UIFont systemFontOfSize:25];
        _sharedAcceptLabel.text = NSLocalizedString(@"Accept", nil);
        _sharedAcceptLabel.textColor = [UIColor whiteColor];
        _sharedAcceptLabel.textAlignment= NSTextAlignmentCenter;
    });

    return _sharedAcceptLabel;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setTitleText:NSLocalizedString(@"My Orders", nil)];

    self.selectedIndexPath = nil;
    self.stripeToken = nil;
    self.creditCardList = nil;

    [self _createTableView];
    [self _fetchOrders];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_fetchOrders) name:kNotificationDidCreateOrder object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_fetchOrders) name:kNotificationDidReceiveBid object:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)_createTableView
{
    self.tableView = [[UITableView alloc] initWithFrame:self.view.frame style:UITableViewStyleGrouped];
    self.tableView.backgroundColor = FlatGray;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.tableView registerClass:[JYBidViewCell class] forCellReuseIdentifier:kBidCellIdentifier];
    [self.view addSubview:self.tableView];

    // Add UIRefreshControl
    UITableViewController *tableViewController = [[UITableViewController alloc] init];
    tableViewController.tableView = self.tableView;

    self.refreshControl = [UIRefreshControl new];
    [self.refreshControl addTarget:self action:@selector(_fetchOrders) forControlEvents:UIControlEventValueChanged];

    tableViewController.refreshControl = self.refreshControl;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.orderList.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    JYOrder *order = self.orderList[section];
    return order.bids.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    JYBidViewCell *cell =
    (JYBidViewCell *)[tableView dequeueReusableCellWithIdentifier:kBidCellIdentifier forIndexPath:indexPath];

    JYOrder *order = self.orderList[indexPath.section];
    JYBid *bid = order.bids[indexPath.row];
    [cell presentBid:bid];
    cell.backgroundColor = bid.statusColor;

    return cell;
}

#pragma mark - UITableView Delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [JYBidViewCell cellHeight];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.selectedIndexPath = indexPath;
    self.tabBarController.tabBar.hidden = YES;

    UICustomActionSheet *actionSheet = [[UICustomActionSheet alloc] initWithTitle:nil delegate:self buttonTitles:@[NSLocalizedString(@"Cancel", nil), NSLocalizedString(@"Accept", nil)]];

    [actionSheet setButtonColors:@[JoyyBlue50, JoyyBlue]];
    [actionSheet setButtonsTextColor:JoyyWhite];
    actionSheet.backgroundColor = JoyyWhite;

    // Highlight the selected cell
    CGRect frame = [tableView cellForRowAtIndexPath:indexPath].frame;
    frame.origin.y -= tableView.contentOffset.y;
    actionSheet.clearArea = frame;

    [actionSheet showInView:self.view];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return [JYOrderCard cardHeightForOrder:self.orderList[section] withAddress:NO andBid:NO];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    JYOrder *order = self.orderList[section];
    CGFloat height = [JYOrderCard cardHeightForOrder:order withAddress:NO andBid:NO];

    JYOrderCard *card = [[JYOrderCard alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(tableView.frame), height)];
    card.tinyLabelsHidden = YES;
    [card presentOrder:order withAddress:NO andBid:NO];
    card.backgroundColor = order.paymentStatusColor;

    return card;
}

#pragma mark - UIActionSheetDelegate

-(void)customActionSheet:(UICustomActionSheet *)customActionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    self.tabBarController.tabBar.hidden = NO;
    if (!self.selectedIndexPath)
    {
        return;
    }

    [self.tableView deselectRowAtIndexPath:self.selectedIndexPath animated:YES];

    if (buttonIndex == 1)
    {
        [self _presentPaymentViewController];
    }
    else
    {
        self.selectedIndexPath = nil;
    }
}

- (void)_onPaymentAuthorizationDone
{
    if ([self _isPaymentReady])
    {
        NSAssert(self.selectedIndexPath != nil, @"selectedIndexPath should not be nil");
        JYOrder *order = self.orderList[self.selectedIndexPath.section];
        JYBid *bid = order.bids[self.selectedIndexPath.row];
        [self _acceptBid:bid forOrder:order];
    }
    else
    {
        // show alert view
    }
    self.selectedIndexPath = nil;
}

- (BOOL)_isPaymentReady
{
    return (self.stripeToken != nil);
}

#pragma mark - Payment

- (void)_presentPaymentViewController
{
    self.stripeToken = nil;

    PKPaymentRequest *request = [Stripe paymentRequestWithMerchantIdentifier:kAppleMerchantId];

    // Configure request
    NSAssert(self.selectedIndexPath != nil, @"selectedIndexPath should not be nil");
    JYOrder *order = self.orderList[self.selectedIndexPath.section];
    JYBid *bid = order.bids[self.selectedIndexPath.row];

    NSNumber *price = [NSNumber numberWithUnsignedInteger:bid.price];
    NSDecimalNumber *amount = [NSDecimalNumber decimalNumberWithDecimal:[price decimalValue]];

    NSString *paymentLineItem = [NSString stringWithFormat:@"Joyy %@ @%@", order.title, bid.username];
    request.paymentSummaryItems = @[[PKPaymentSummaryItem summaryItemWithLabel:paymentLineItem amount:amount]];

    if ([Stripe canSubmitPaymentRequest:request])
    {
        // show Apple Pay view
        PKPaymentAuthorizationViewController *paymentController = [[PKPaymentAuthorizationViewController alloc] initWithPaymentRequest:request];
        paymentController.delegate = self;
        [self presentViewController:paymentController animated:YES completion:nil];
    }
    else if (self.creditCardList)
    {
        [self _doPresentPaymentViewController];
    }
    else
    {
        [self _fetchCreditCards];
    }
}

- (void)_doPresentPaymentViewController
{
    JYPaymentViewController *viewController = [JYPaymentViewController new];
    viewController.delegate = self;
    viewController.creditCardList = self.creditCardList;
    [self.navigationController pushViewController:viewController animated:YES];
}

#pragma mark - PKPaymentAuthorizationViewControllerDelegate (Apple Pay)

- (void)paymentAuthorizationViewController:(PKPaymentAuthorizationViewController *)controller
                       didAuthorizePayment:(PKPayment *)payment
                                completion:(void (^)(PKPaymentAuthorizationStatus))completion
{

    __weak typeof(self) weakSelf = self;
    [[STPAPIClient sharedClient] createTokenWithPayment:payment
                                             completion:^(STPToken *token, NSError *error) {
                                                 if (error)
                                                 {
                                                     weakSelf.stripeToken = nil;
                                                     completion(PKPaymentAuthorizationStatusFailure);
                                                     return;
                                                 }
                                                 weakSelf.stripeToken = token.tokenId;
                                                 NSLog(@"stripeToken = %@", weakSelf.stripeToken);
                                                 completion(PKPaymentAuthorizationStatusSuccess);
                                             }];
}

- (void)paymentAuthorizationViewControllerDidFinish:(PKPaymentAuthorizationViewController *)controller
{
    [self dismissViewControllerAnimated:YES completion:nil];
    [self _onPaymentAuthorizationDone];
}

#pragma mark - JYPaymentViewControllerDelegate

- (void)viewController:(JYPaymentViewController *)controller didCreateToken:(NSString *)token
{
    self.stripeToken = token;
}

- (void)viewControllerDidFinish:(JYPaymentViewController *)controller
{
    [self.navigationController popViewControllerAnimated:YES];
    [self _onPaymentAuthorizationDone];
}

#pragma mark - Network

- (void)_fetchCreditCards
{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSString *token = [NSString stringWithFormat:@"Bearer %@", [JYUser currentUser].token];
    [manager.requestSerializer setValue:token forHTTPHeaderField:@"Authorization"];

    NSString *url = [NSString stringWithFormat:@"%@%@", kUrlAPIBase, @"creditcards/my"];

    [KVNProgress show];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

    __weak typeof(self) weakSelf = self;
    [manager GET:url
      parameters:nil
         success:^(AFHTTPRequestOperation *operation, id responseObject) {
             NSLog(@"/creditcards/my fetch success responseObject: %@", responseObject);

             [KVNProgress dismiss];
             [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

             weakSelf.creditCardList = [NSMutableArray new];
             for (NSDictionary *dict in responseObject)
             {
                 JYCreditCard *card = [[JYCreditCard alloc] initWithDictionary:dict];
                 [weakSelf.creditCardList addObject:card];
             }

             [weakSelf _doPresentPaymentViewController];
         }
         failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             [KVNProgress dismiss];
             [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

             [weakSelf _doPresentPaymentViewController];
         }
     ];
}

- (void)_acceptBid:(JYBid *)bid forOrder:(JYOrder *)order
{
    [self networkThreadBegin];
    NSDictionary *parameters = @{@"id": @(bid.bidId), @"stripe_token": self.stripeToken};

    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSString *token = [NSString stringWithFormat:@"Bearer %@", [JYUser currentUser].token];
    [manager.requestSerializer setValue:token forHTTPHeaderField:@"Authorization"];

    NSString *url = [NSString stringWithFormat:@"%@%@", kUrlAPIBase, @"bids/accept"];

    __weak typeof(self) weakSelf = self;
    [manager POST:url
      parameters:parameters
         success:^(AFHTTPRequestOperation *operation, id responseObject) {
             NSLog(@"bids/accept post success responseObject: %@", responseObject);

             order.status = JYOrderStatusPending;
             bid.status = JYBidStatusAccepted;

             [weakSelf networkThreadEnd];
         }
         failure:^(AFHTTPRequestOperation *operation, NSError *error) {

             NSLog(@"bids/accept post error: %@", error);
             [weakSelf networkThreadEnd];
         }
     ];
}

- (void)_fetchOrders
{
    if (self.networkThreadCount > 0)
    {
        return;
    }
    [self networkThreadBegin];

    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSString *token = [NSString stringWithFormat:@"Bearer %@", [JYUser currentUser].token];
    [manager.requestSerializer setValue:token forHTTPHeaderField:@"Authorization"];

    NSString *url = [NSString stringWithFormat:@"%@%@", kUrlAPIBase, @"orders/unpaid"];

    __weak typeof(self) weakSelf = self;
    [manager GET:url
      parameters:nil
         success:^(AFHTTPRequestOperation *operation, id responseObject) {
             NSLog(@"orders/unpaid fetch success responseObject: %@", responseObject);

             weakSelf.orderList = [NSMutableArray new];
             for (NSDictionary *dict in responseObject)
             {
                 JYOrder *newOrder = [[JYOrder alloc] initWithDictionary:dict];
                 [weakSelf.orderList addObject:newOrder];
             }

             if (weakSelf.orderList.count > 0)
             {
                 [weakSelf _fetchBidsForOrders];
             }
             [weakSelf networkThreadEnd];
         }
         failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             [weakSelf networkThreadEnd];
         }
     ];
}

- (void)_fetchBidsForOrders
{
    [self networkThreadBegin];

    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSString *token = [NSString stringWithFormat:@"Bearer %@", [JYUser currentUser].token];
    [manager.requestSerializer setValue:token forHTTPHeaderField:@"Authorization"];

    NSString *url = [NSString stringWithFormat:@"%@%@", kUrlAPIBase, @"bids/of/orders"];

    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

    __weak typeof(self) weakSelf = self;
    [manager GET:url
      parameters:[self _httpBidsParameters]
         success:^(AFHTTPRequestOperation *operation, id responseObject) {

             NSLog(@"bids/of/orders fetch success responseObject: %@", responseObject);
             for (NSDictionary *dict in responseObject)
             {
                 JYBid *bid = [[JYBid alloc] initWithDictionary:dict];
                 JYOrder *order = [weakSelf orderOfId:bid.orderId];
                 if (order != nil)
                 {
                     if (order.status == JYOrderStatusActive ||
                         (order.status == JYOrderStatusPending && bid.status == JYBidStatusAccepted))
                     {
                         [order.bids addObject:bid];
                     }
                 }
             }

             [weakSelf networkThreadEnd];
             NSIndexPath *indexPath = [NSIndexPath indexPathForRow:NSNotFound inSection:0];
             [weakSelf.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
         }
         failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             [weakSelf networkThreadEnd];
         }
     ];
}

- (NSDictionary *)_httpBidsParameters
{
    NSMutableArray *orderIds = [NSMutableArray new];
    for (JYOrder *order in self.orderList)
    {
        [orderIds addObject:@(order.orderId)];
    }

    NSMutableDictionary *parameters = [NSMutableDictionary new];

    [parameters setValue:orderIds forKey:@"order_id"];

    return parameters;
}

@end
