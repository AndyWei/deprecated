//
//  JYPaymentViewController.m
//  joyyios
//
//  Created by Ping Yang on 6/18/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import <AFNetworking/AFNetworking.h>
#import <KVNProgress/KVNProgress.h>
#import <RKDropdownAlert/RKDropdownAlert.h>
#import <PaymentKit/PTKView.h>

#import "JYButton.h"
#import "JYCreditCardViewCell.h"
#import "JYPaymentViewController.h"
#import "JYUser.h"

@interface JYPaymentViewController () <PTKViewDelegate, UITableViewDataSource, UITableViewDelegate>

@property(nonatomic) NSInteger networkThreadCount;
@property(nonatomic) NSMutableArray *cardList;
@property(nonatomic) NSString *stripeToken;

@property(nonatomic, weak) JYButton *saveButton;
@property(nonatomic, weak) PTKView *paymentView;
@property(nonatomic, weak) UITableView *tableView;

@end

static NSString *const kCardCellIdentifier = @"cardCell";

@implementation JYPaymentViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.stripeToken = nil;
    self.networkThreadCount = 0;
    self.cardList = [NSMutableArray new];

    [self _createTableView];
    [self _fetchCreditCards];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)_createTableView
{
    UITableView *tableView = [[UITableView alloc] initWithFrame:self.view.frame style:UITableViewStyleGrouped];
    tableView.backgroundColor = JoyyWhite;
    tableView.dataSource = self;
    tableView.delegate = self;
    [tableView registerClass:[JYCreditCardViewCell class] forCellReuseIdentifier:kCardCellIdentifier];

    self.tableView = tableView;
    [self.view addSubview:self.tableView];
}

- (void)_createPaymentView
{
    PTKView *view = [[PTKView alloc] initWithFrame:CGRectMake(8, 80, 290, 55)];
    self.paymentView = view;
    self.paymentView.delegate = self;

    [self.view addSubview:self.paymentView];
}

- (void)_createSaveButton
{
    CGFloat x = CGRectGetMaxX(self.paymentView.frame) + 8;
    CGFloat width = CGRectGetWidth([[UIScreen mainScreen] applicationFrame]) - x - 8;
    CGRect frame = CGRectMake(x, 80, width, 45);

    JYButton *button = [[JYButton alloc] initWithFrame:frame buttonStyle:JYButtonStyleDefault];

    button.backgroundColor = ClearColor;
    button.contentAnimateToColor = FlatGreen;
    button.contentColor = FlatWhite;
    button.cornerRadius = 8;
    button.foregroundAnimateToColor = FlatWhite;
    button.foregroundColor = FlatGreen;
    button.textLabel.font = [UIFont boldSystemFontOfSize:16];
    button.textLabel.text = NSLocalizedString(@"Save", nil);
    [button addTarget:self action:@selector(_save) forControlEvents:UIControlEventTouchUpInside];

    self.saveButton = button;
    self.saveButton.enabled = NO;
    [self.view addSubview:self.saveButton];
}

- (void)_save
{
    STPCard *card = [[STPCard alloc] init];
    card.number = self.paymentView.card.number;
    card.expMonth = self.paymentView.card.expMonth;
    card.expYear = self.paymentView.card.expYear;
    card.cvc = self.paymentView.card.cvc;

    __weak typeof(self) weakSelf = self;
    [[STPAPIClient sharedClient] createTokenWithCard:card
                                          completion:^(STPToken *token, NSError *error) {
                                              if (error)
                                              {
                                                  NSString *errorMessage = error.localizedDescription;
                                                  [RKDropdownAlert title:NSLocalizedString(kErrorTitle, nil)
                                                                 message:errorMessage
                                                         backgroundColor:FlatYellow
                                                               textColor:FlatBlack
                                                                    time:5];
                                              }
                                              else
                                              {
                                                  weakSelf.stripeToken = token.tokenId;
                                                  [weakSelf _submitCreditCard];
                                              }
                                          }];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.cardList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    JYCreditCardViewCell *cell =
    (JYCreditCardViewCell *)[tableView dequeueReusableCellWithIdentifier:kCardCellIdentifier forIndexPath:indexPath];

    JYCreditCard *card = self.cardList[indexPath.row];
    [cell presentCreditCard:card];
    return cell;
}

#pragma mark - UITableView Delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [JYCreditCardViewCell cellHeight];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{

}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 55;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(8, 40, 300, 55)];
    label.backgroundColor = ClearColor;
    label.font = [UIFont systemFontOfSize:22];
    label.textColor = FlatBlack;
    label.textAlignment = NSTextAlignmentLeft;
    label.text = NSLocalizedString(@"Choose a credit card:", nil);

    return label;
}

#pragma mark - PTKViewDelegate

- (void)paymentView:(PTKView *)view withCard:(PTKCard *)card isValid:(BOOL)valid
{
    self.saveButton.enabled = valid;
}

#pragma mark - Network

- (void)networkThreadBegin
{
    if (self.networkThreadCount == 0)
    {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    }
    self.networkThreadCount++;
}

- (void)networkThreadEnd
{
    self.networkThreadCount--;
    if (self.networkThreadCount <= 0)
    {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        [self.tableView reloadData];
    }
}

- (void)_fetchCreditCards
{
    if (self.networkThreadCount > 0)
    {
        return;
    }
    [self networkThreadBegin];

    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSString *token = [NSString stringWithFormat:@"Bearer %@", [JYUser currentUser].token];
    [manager.requestSerializer setValue:token forHTTPHeaderField:@"Authorization"];

    NSString *url = [NSString stringWithFormat:@"%@%@", kUrlAPIBase, @"creditcards/my"];

    __weak typeof(self) weakSelf = self;
    [manager GET:url
      parameters:nil
         success:^(AFHTTPRequestOperation *operation, id responseObject) {
             NSLog(@"/creditcards/my fetch success responseObject: %@", responseObject);

             weakSelf.cardList = [NSMutableArray new];
             for (NSDictionary *dict in responseObject)
             {
                 JYCreditCard *card = [[JYCreditCard alloc] initWithDictionary:dict];
                 [weakSelf.cardList addObject:card];
             }

             [weakSelf networkThreadEnd];
         }
         failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             [weakSelf networkThreadEnd];
         }
     ];
}

- (void)_submitCreditCard
{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSString *token = [NSString stringWithFormat:@"Bearer %@", [JYUser currentUser].token];
    [manager.requestSerializer setValue:token forHTTPHeaderField:@"Authorization"];

    NSString *url = [NSString stringWithFormat:@"%@%@", kUrlAPIBase, @"creditcards"];
    NSMutableDictionary *parameters = [self _submitCreditCardParameters];

    NSLog(@"parameters: %@", parameters);

    [KVNProgress show];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

    __weak typeof(self) weakSelf = self;
    [manager POST:url
       parameters:parameters
          success:^(AFHTTPRequestOperation *operation, id responseObject) {
              NSLog(@"Credit card submit success responseObject: %@", responseObject);

              [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
              [KVNProgress dismiss];

              NSDictionary *result = (NSDictionary *)responseObject;
              NSString *stripeCustomerId = [result valueForKey:@"customer_id"];
              [weakSelf.delegate viewController:weakSelf didCreateToken:stripeCustomerId];
              [weakSelf.delegate viewControllerDidFinish:weakSelf];
          }
          failure:^(AFHTTPRequestOperation *operation, NSError *error) {

              [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
              [KVNProgress dismiss];

              [weakSelf.delegate viewController:weakSelf didCreateToken:nil];
              NSString *errorMessage = NSLocalizedString(@"Can't save the credit card due to network failure, please retry later", nil);
              [RKDropdownAlert title:NSLocalizedString(kErrorTitle, nil)
                             message:errorMessage
                     backgroundColor:FlatYellow
                           textColor:FlatBlack
                                time:5];
          }
     ];

}

- (NSMutableDictionary *)_submitCreditCardParameters
{
    NSMutableDictionary *parameters = [NSMutableDictionary new];

    [parameters setValue:@(self.paymentView.card.expYear) forKey:@"expiry_year"];
    [parameters setValue:@(self.paymentView.card.expMonth) forKey:@"expiry_month"];
    [parameters setValue:self.paymentView.card.last4 forKey:@"number_last_4"];
    [parameters setValue:[JYUser currentUser].email forKey:@"email"];
    [parameters setValue:self.stripeToken forKey:@"stripe_token"];

    return parameters;
}

@end
