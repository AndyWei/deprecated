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
#import <Stripe/Stripe.h>

#import "JYButton.h"
#import "JYCreditCardViewCell.h"
#import "JYPaymentViewController.h"
#import "JYUser.h"

@interface JYPaymentViewController ()

@property(nonatomic) JYCreditCardType cardType;
@property(nonatomic) STPCard *stpCard;
@property(nonatomic) NSMutableArray *creditCardList;
@property(nonatomic) NSString *stripeToken;

@property(nonatomic, weak) JYButton *addButton;

@end


static NSString *const kCardCellIdentifier = @"cardCell";

@implementation JYPaymentViewController

- (BOOL)hidesBottomBarWhenPushed
{
    return YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationItem.title = NSLocalizedString(@"Payment", nil);
    self.view.backgroundColor = JoyyWhite;

    self.cardType = JYCreditCardTypeUnrecognized;
    self.stpCard = nil;
    self.stripeToken = nil;
    self.creditCardList = [NSMutableArray new];

    [self _createTableView];
    [self _fetchCreditCards];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)_createTableView
{
    CGFloat y = CGRectGetMaxY(self.addButton.frame) + 10;

    CGRect frame =  CGRectMake(0, y, CGRectGetWidth(self.view.frame), 500);
    UITableView *tableView = [[UITableView alloc] initWithFrame:frame style:UITableViewStylePlain];
    tableView.backgroundColor = JoyyWhite;
    tableView.dataSource = self;
    tableView.delegate = self;
    [tableView registerClass:[JYCreditCardViewCell class] forCellReuseIdentifier:kCardCellIdentifier];

    self.tableView = tableView;
    [self.view addSubview:self.tableView];
}

- ( BOOL)_isApplePayConfigured
{
    if (![PKPaymentAuthorizationViewController class])
    {
        return NO;
    }

    NSArray *networks = @[PKPaymentNetworkAmex, PKPaymentNetworkMasterCard, PKPaymentNetworkVisa];

    BOOL deviceOK = [PKPaymentAuthorizationViewController canMakePayments];
    BOOL cardOK = [PKPaymentAuthorizationViewController canMakePaymentsUsingNetworks:networks];
    return deviceOK && cardOK;
}

- (void)_createCreditCardListFromArray:(NSArray *)array
{
    BOOL hasSetDefault = NO;
    JYCreditCard *applePay = nil;
    self.creditCardList = [NSMutableArray new];


    // apple pay
    if ([self _isApplePayConfigured])
    {
        applePay = [JYCreditCard applePayCard];
        [self.creditCardList addObject:applePay];
    }

    // real creadit cards
    for (NSDictionary *dict in array)
    {
        JYCreditCard *card = [[JYCreditCard alloc] initWithDictionary:dict];
        if ([card isDefault])
        {
            hasSetDefault = YES;
        }
        [self.creditCardList addObject:card];
    }

    // set apply pay as default
    if (!hasSetDefault && applePay)
    {
        [applePay setAsDefault];
    }

    // the dummy card for the "add new card" cell
    [self.creditCardList addObject:[JYCreditCard dummyCard]];
}

- (void)_didAddCreditCardWithCustomerId:(NSString *)customerId
{
    NSAssert(self.creditCardList.count > 0, @"self.creditCardList should contain at least the dummy card");

    NSInteger index = self.creditCardList.count - 1;

    JYCreditCard *newCard = [JYCreditCard cardWithType:self.cardType fromSTPCard:self.stpCard];
    newCard.stripeCustomerId = customerId;
    [newCard setAsDefault];

    [self.creditCardList insertObject:newCard atIndex:index];

    [self.tableView reloadData];
}

- (void)_presentCreditCardScanner
{
    CardIOPaymentViewController *scanViewController = [[CardIOPaymentViewController alloc] initWithPaymentDelegate:self];
    scanViewController.modalPresentationStyle = UIModalPresentationFormSheet;
    [self presentViewController:scanViewController animated:YES completion:nil];
}

#pragma mark - CardIOPaymentViewControllerDelegate

- (void)userDidProvideCreditCardInfo:(CardIOCreditCardInfo *)info inPaymentViewController:(CardIOPaymentViewController *)paymentViewController
{
    NSLog(@"Credit card scan succeeded with card number = %@", info.cardNumber);

    self.stpCard = [[STPCard alloc] init];
    self.stpCard.number = info.cardNumber;
    self.stpCard.expMonth = info.expiryMonth;
    self.stpCard.expYear = info.expiryYear;
    self.stpCard.cvc = info.cvv;

    self.cardType = (JYCreditCardType)info.cardType;

    __weak typeof(self) weakSelf = self;
    [[STPAPIClient sharedClient] createTokenWithCard:self.stpCard
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
                                                  [weakSelf dismissViewControllerAnimated:YES completion:nil];
                                                  weakSelf.stripeToken = token.tokenId;
                                                  [weakSelf _submitCreditCard];
                                              }
                                          }];
}

- (void)userDidCancelPaymentViewController:(CardIOPaymentViewController *)paymentViewController
{
    NSLog(@"User cancelled scan");
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.creditCardList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    JYCreditCardViewCell *cell =
    (JYCreditCardViewCell *)[tableView dequeueReusableCellWithIdentifier:kCardCellIdentifier forIndexPath:indexPath];

    JYCreditCard *card = self.creditCardList[indexPath.row];
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
    [tableView deselectRowAtIndexPath:indexPath animated:YES];


    if (indexPath.row == self.creditCardList.count - 1)
    {
        [self _presentCreditCardScanner];
    }
    else
    {
        JYCreditCard *card = self.creditCardList[indexPath.row];
        [card setAsDefault];
        [tableView reloadData];
    }

//    if (self.delegate)
//    {
//        [self.delegate viewControllerDidCreateToken:card.stripeCustomerId];
//        [self.delegate viewControllerDidFinish:self];
//    }
}

#pragma mark - Network

- (void)_fetchCreditCards
{
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

             [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

             [weakSelf _createCreditCardListFromArray:responseObject];
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
              NSString *customerId = [result valueForKey:@"customer_id"];
              [weakSelf _didAddCreditCardWithCustomerId:customerId];

//              if (weakSelf.delegate)
//
//                  [weakSelf.delegate viewControllerDidCreateToken:stripeCustomerId];
//                  [weakSelf.delegate viewControllerDidFinish:weakSelf];
//              }
          }
          failure:^(AFHTTPRequestOperation *operation, NSError *error) {

              [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
              [KVNProgress dismiss];

//              if (weakSelf.delegate)
//              {
//                  [weakSelf.delegate viewControllerDidCreateToken:nil];
//              }

              [RKDropdownAlert title:NSLocalizedString(kErrorTitle, nil)
                             message:error.localizedDescription
                     backgroundColor:FlatYellow
                           textColor:FlatBlack
                                time:5];
          }
     ];

}

- (NSMutableDictionary *)_submitCreditCardParameters
{
    NSMutableDictionary *parameters = [NSMutableDictionary new];

    [parameters setValue:@(self.cardType) forKey:@"card_type"];
    [parameters setValue:@(self.stpCard.expYear) forKey:@"expiry_year"];
    [parameters setValue:@(self.stpCard.expMonth) forKey:@"expiry_month"];
    [parameters setValue:self.stpCard.last4 forKey:@"number_last_4"];
    [parameters setValue:[JYUser currentUser].email forKey:@"email"];
    [parameters setValue:self.stripeToken forKey:@"stripe_token"];

    return parameters;
}

@end
